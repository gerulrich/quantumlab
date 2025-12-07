# Cilium API Gateway

Esta guía detalla los pasos necesarios para instalar Cilium como CNI y habilitar la API Gateway en un clúster Kubernetes. Cilium proporciona redes seguras y observables para cargas de trabajo nativas de la nube, mientras que la API Gateway permite gestionar el tráfico entrante al clúster.

> ⏱️ Tiempo estimado de implementación: 15-20 minutos

---

## 1. 🗂 Requisitos previos

Asegúrate de tener las siguientes herramientas y componentes instalados antes de comenzar:

- [`helm`](https://helm.sh/docs/intro/install/) - Gestor de paquetes para Kubernetes
- [`cilium`](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/) - CLI de Cilium (opcional, para diagnósticos)

---

## 2. 🔄 Preparar el clúster para Cilium

### Aplicar patch CNI en Talos

Primero, necesitamos configurar Talos para desactivar kube-proxy y configurar el CNI en modo "none", ya que Cilium reemplazará estas funcionalidades:

```bash
# Aplicar el patch a la configuración de Talos
talosctl patch machineconfig -n $CONTROL_PLANE_IP --patch @config/quantum-talos/cni.patch.yaml --endpoints $CONTROL_PLANE_IP --mode=reboot

# Importante: Espera a que todos los nodos reinicien y estén en estado "Ready"
# Puedes verificar el estado desde el dashboard de Talos
talosctl dashboard --nodes $CONTROL_PLANE_IP
```

> ⚠️ No continúes hasta que todos los nodos estén completamente operativos después del reinicio. El clúster puede tardar unos minutos en estabilizarse.

---

## 3. 🧾 Instalar Gateway API

La Gateway API proporciona recursos para configurar enrutamiento, balanceo de carga y más. Esta es una dependencia de Cilium API Gateway:

```bash
# Instalar los CRDs de la Gateway API
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/standard-install.yaml

# Instalar recursos experimentales (TLS Routes)
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.4.1/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml
```

> 📝 Estos comandos instalan las definiciones de recursos personalizados (CRDs) necesarias para la API Gateway.

---

## 4. 🧩 Instalar Cilium con API Gateway

Instalamos Cilium utilizando Helm para generar el manifiesto y luego lo aplicamos:

```bash
# Agregar el repositorio de Cilium a Helm
helm repo add cilium https://helm.cilium.io/
helm repo update

# Generar el manifiesto de Cilium con las opciones adecuadas
helm template \
    cilium \
    cilium/cilium \
    --version 1.18.4 \
    --namespace kube-system \
    --set ipam.mode=kubernetes \
    --set l2announcements.enabled=true \
    --set l2announcements.leaseDuration="3s" \
    --set l2announcements.leaseRenewDeadline="1s" \
    --set l2announcements.leaseRetryPeriod="500ms" \
    --set k8sClientRateLimit.qps=32 \
    --set k8sClientRateLimit.burst=33 \
    --set kubeProxyReplacement=true \
    --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --set cgroup.autoMount.enabled=false \
    --set cgroup.hostRoot=/sys/fs/cgroup \
    --set k8sServiceHost=localhost \
    --set k8sServicePort=7445 \
    --set gatewayAPI.enabled=true \
    --set gatewayAPI.enableAlpn=true \
    --set gatewayAPI.enableAppProtocol=true \
    --set bgpControlPlane.enabled=true \
    --set externalIPs.enabled=true  \
    --set devices="{enp1s0}" \
    --api-versions='gateway.networking.k8s.io/v1/GatewayClass' > config/cillium/cilium.yaml

# Aplicar el manifiesto generado
kubectl apply -f config/cillium/cilium.yaml
```

### Monitores el progreso de la instalación

```bash
# Monitorear que todos los pods se inicien correctamente
watch -w -t -n 2 kubectl get all -A
```

> 🔍 Espera a que todos los pods de Cilium estén en estado "Running" antes de continuar con el siguiente paso.

### Eliminar kube-proxy (si aún existe)

```bash
# Verificar si kube-proxy está ejecutándose
kubectl get daemonset kube-proxy -n kube-system 

# Si existe, eliminarlo
kubectl delete daemonset kube-proxy -n kube-system
```

---

## 5. ✅ Verificar la instalación de Cilium

Es importante comprobar que Cilium está funcionando correctamente antes de continuar:

```bash
# Ejecutar el test de conectividad de Cilium
cilium connectivity test
```

> ⚠️ Si la prueba se queda en estado "Waiting", ejecuta los siguientes comando desde otra terminal:

```bash
kubectl label namespace cilium-test-1 pod-security.kubernetes.io/enforce=privileged
kubectl label namespace cilium-test-ccnp1 pod-security.kubernetes.io/enforce=privileged
kubectl label namespace cilium-test-ccnp2 pod-security.kubernetes.io/enforce=privileged
```

Una vez completada la prueba, limpia los recursos creados:

```bash
# Eliminar namespaces de prueba
kubectl delete namespace cilium-test-1
kubectl delete namespace cilium-test-ccnp1
kubectl delete namespace cilium-test-ccnp2
```

---

## 6. 🌐 Configurar recursos de red

### Configurar Pool de IPs

Debes crear un pool de IPs para que Cilium pueda asignarlas a los servicios:

```bash
# Aplicar configuración del pool de IPs
kubectl apply -f config/cillium/ip_pool.yaml
```

> ⚠️ Asegúrate de editar `config/cillium/ip_pool.yaml` para que las IPs correspondan a tu red y que no se solapen con las IPs usadas para DHCP.

### Configurar política de anuncio

```bash
# Aplicar la política de anuncio de IPs
kubectl apply -f config/cillium/advert_policy.yaml
```

### Configurar compartición de IP en Load Balancers

Cilium permite que múltiples servicios compartan la misma dirección IP utilizando la anotación `io.cilium/lb-ipam-sharing-key`. Esto es especialmente útil para Gateways que manejan tráfico HTTP y HTTPS en la misma dirección IP pero diferentes puertos.

#### Anotación `io.cilium/lb-ipam-sharing-key`

Esta anotación permite que servicios de tipo LoadBalancer compartan la misma dirección IP cuando tienen el mismo valor de clave de compartición:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: tls-gateway
  namespace: gateway
spec:
  gatewayClassName: cilium
  infrastructure:
    annotations:
      "io.cilium/lb-ipam-sharing-key": "internal-traffic"
    labels:
      color: blue
  listeners:
  - name: https-listener
    protocol: HTTPS
    port: 443
    # ... resto de la configuración
```

**Características principales**:

- **Compartición de IP**: Servicios con el mismo valor en `lb-ipam-sharing-key` compartirán la misma dirección IP externa
- **Separación por puerto**: Cada servicio debe usar puertos diferentes (ej: 80 para HTTP, 443 para HTTPS)
- **Optimización de recursos**: Reduce el número de IPs públicas necesarias
- **Agrupación lógica**: Permite agrupar servicios relacionados bajo la misma IP

**Casos de uso comunes**:

1. **HTTP/HTTPS Gateways**: Compartir IP entre gateway HTTP (puerto 80) y HTTPS (puerto 443)
2. **Servicios relacionados**: Múltiples servicios de la misma aplicación que necesitan la misma IP externa
3. **Optimización de red**: Reducir el consumo de direcciones IP en redes con IPs limitadas

**Ejemplo práctico en QuantumLab**:

En este proyecto, tanto `http-gateway` como `tls-gateway` usan la clave `"internal-traffic"`, lo que significa que ambos gateways compartirán la misma dirección IP externa:

- `http-gateway`: puerto 80 (HTTP)
- `tls-gateway`: puerto 443 (HTTPS)

Esto permite que el tráfico web llegue a la misma IP y Cilium enrute automáticamente:
- Tráfico puerto 80 → Gateway HTTP
- Tráfico puerto 443 → Gateway HTTPS

> 📝 **Nota importante**: Los servicios que comparten IP deben usar puertos diferentes. Si intentas usar el mismo puerto con la misma clave de compartición, la configuración fallará.

---

## 7. 🔎 Verificación y resolución de problemas

Para verificar el estado de Cilium y solucionar posibles problemas:

```bash
# Verificar estado de los agentes de Cilium
kubectl -n kube-system get pods -l k8s-app=cilium

# Revisar logs de un pod específico de Cilium
kubectl -n kube-system logs <nombre-del-pod-cilium>

# Verificar servicios LoadBalancer y sus IPs asignadas
kubectl get svc -A --field-selector spec.type=LoadBalancer

# Ver Gateways y sus direcciones IP compartidas
kubectl get gateway -n gateway -o wide

# Verificar que los Gateways comparten la misma IP
kubectl get gateway -n gateway -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.addresses[0].value}{"\n"}{end}'

# Verificar anotaciones de Load Balancer en los servicios de Cilium
kubectl get svc -n kube-system -l io.cilium/gateway-owning-gateway -o yaml | grep -A5 -B5 "lb-ipam-sharing-key"

```

---

## 8. 🛠 Mantenimiento y operaciones comunes

Estos comandos te serán útiles para el mantenimiento diario:

```bash
# Actualizar Cilium (generar nuevo manifiesto con la nueva versión)
helm template cilium cilium/cilium --version <nueva-versión> ... > cilium-new.yaml
kubectl apply -f cilium-new.yaml

# Reiniciar todos los pods de Cilium
kubectl -n kube-system delete pods -l k8s-app=cilium

# Ver estado y métricas de Cilium
cilium status
```

Para más información, consulta la [documentación oficial de Cilium](https://docs.cilium.io/) y la [documentación de Gateway API](https://gateway-api.sigs.k8s.io/).
