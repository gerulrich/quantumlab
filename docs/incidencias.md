# Registro de incidencias

Historial de problemas del homelab, independientemente del componente afectado. Cada entrada recoge la fecha, el fallo, la causa, el diagnóstico, la solución y el resultado. Las incidencias más recientes se añaden primero.

## 2026-10-23: HTTP/HTTPS inaccesible tras actualizar Cilium a 1.20.4

**Fallo:** después de actualizar de Cilium 1.20.3 a 1.20.4 (commit `8935690`), la IP del Gateway (`10.10.10.50`) rechazaba conexiones en los puertos 80 y 443. DNS resolvía correctamente, los pods estaban `Running` y los Gateways mostraban `Programmed=True`, pero Envoy no tenía listeners de aplicaciones.

**Causa observada:** con `envoy.xdsMode` sin definir, el nuevo chart generó un bootstrap de Envoy con servicios xDS separados (LDS/CDS), mientras el agente conservaba `envoy-xds-mode: ads`. Esa discrepancia impedía entregar la configuración a Envoy; no era un fallo de DNS ni del certificado TLS.

**Cómo se detectó:** cargar el entorno y consultar el estado y los logs:

```bash
source scripts/quantum-env.sh
kubectl get gateway -A
kubectl -n kube-system logs -l k8s-app=cilium-envoy --since=10m --tail=50 --prefix
kubectl -n kube-system get cm cilium-config -o go-template='{{index .data "envoy-xds-mode"}}{{"\n"}}'
kubectl -n kube-system exec ds/cilium -- cilium-dbg envoy admin listeners
```

Los logs repetían `unknown service envoy.service.listener.v3.ListenerDiscoveryService` y `unknown service envoy.service.cluster.v3.ClusterDiscoveryService`. El agente indicaba `ads`, pero Envoy solo mostraba listeners de salud y métricas, sin los de HTTP/HTTPS. La prueba directa, sin depender de DNS, devolvía `Connection refused`:

```bash
curl -v --connect-timeout 5 --resolve nginx.lan.homelab.net.ar:80:10.10.10.50 http://nginx.lan.homelab.net.ar/
```

**Solución:** fijar explícitamente ADS en `spec.values` del [HelmRelease de Cilium](../helm/cilium/release.yaml):

```yaml
envoy:
  xdsMode: ads
```

Una vez publicado el cambio en Git y reconciliado el HelmRelease por Flux, reiniciar Envoy de forma gradual. Actualizar el ConfigMap no bastó: los procesos conservaban el bootstrap anterior en memoria.

```bash
flux reconcile helmrelease cilium -n kube-system
kubectl -n kube-system rollout restart ds/cilium-envoy
kubectl -n kube-system rollout status ds/cilium-envoy --timeout=240s
kubectl -n kube-system exec ds/cilium -- cilium-dbg envoy admin listeners
curl --connect-timeout 5 --resolve nginx.lan.homelab.net.ar:443:10.10.10.50 https://nginx.lan.homelab.net.ar/
```

**Resultado:** reaparecieron los listeners de ambos Gateways. NGINX respondió `200` por HTTP y HTTPS con certificado válido; Homepage devolvió `200` y Radarr `302`. No fue necesario bajar la versión de Cilium.