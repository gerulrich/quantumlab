# Cloudflared

Esta guía explica cómo gestionar el túnel de Cloudflare (`cloudflared`) para publicar servicios del clúster mediante una conexión segura, sin exponer puertos públicos.

## Introducción

El túnel de Cloudflare (`quantum-k8s-tunnel`) se ejecuta como un deployment en Kubernetes y mantiene una conexión persistente con la red de Cloudflare. Esto permite exponer servicios internos del clúster sin abrir puertos en el firewall.

**Ventajas:**
- No requiere puertos abiertos públicamente
- SSL/TLS automático

## Gestión del Túnel desde OpenTofu

La configuración se divide en dos partes:

- **Infraestructura en Cloudflare (OpenTofu):** túnel y registros DNS en `config/opentofu/cloudflare.tf`.
- **Enrutamiento interno en Kubernetes (ConfigMap):** reglas `ingress` en `apps/base/cloudflared/config-map.yaml`.

Este enfoque mantiene toda la configuración versionada en Git y evita la administración manual del túnel fuera de OpenTofu.

## Configuración de DNS con OpenTofu

### Variables necesarias

Define en `config/opentofu/terraform.tfvars`:

- `cloudflare_enabled = true`
- `cloudflare_api_token`
- `cloudflare_account_id`
- `cloudflare_zone_id`
- `cloudflare_domain_name`

### Dónde se define cada hostname

En `config/opentofu/cloudflare.tf`, el recurso `cloudflare_dns_record.tunnel_routes` usa un `for_each` con los subdominios publicados por el túnel.

Ejemplo:

```hcl
for_each = var.cloudflare_enabled ? toset([
  "ng",     # ng.<dominio>
  "photos", # photos.<dominio>
]) : toset([])
```

Con eso, OpenTofu crea el CNAME como proxy a `<tunnel_id>.cfargotunnel.com` para cada host.

### Aplicar cambios de DNS

```bash
source scripts/quantum-env.sh
tofu plan
tofu apply
```

## Configuración de ingress en Cloudflared (ConfigMap)

El archivo `apps/base/cloudflared/config-map.yaml` controla cómo `cloudflared` enruta cada hostname al servicio interno de Kubernetes.

Ejemplo base:

```yaml
data:
  config.yaml: |
    tunnel: quantum-k8s-tunnel
    credentials-file: /etc/cloudflared/creds/credentials.json
    metrics: 0.0.0.0:2000
    no-autoupdate: true
    ingress:
    - hostname: ng.${DOMAIN}
      service: http://nginx.nginx.svc.cluster.local:80
    - service: http_status:404
```

### Parámetros importantes

- `tunnel`: nombre del túnel que debe coincidir con el túnel administrado por OpenTofu.
- `credentials-file`: ruta al secreto montado con las credenciales del túnel.
- `metrics`: endpoint de métricas de `cloudflared`.
- `no-autoupdate`: evita autoactualizaciones fuera del flujo GitOps.
- `ingress`: lista ordenada de reglas de enrutamiento.
- `hostname`: FQDN público que llega por Cloudflare.
- `service`: destino interno en Kubernetes (`http://servicio.namespace.svc.cluster.local:puerto`).
- `http_status:404`: regla final de fallback para tráfico no coincidente.

## Checklist rápido para un nuevo ingress

1. DNS: agrega el subdominio en `config/opentofu/cloudflare.tf`.
2. Routing: agrega la regla `hostname` + `service` en `apps/base/cloudflared/config-map.yaml`.
3. OpenTofu: ejecuta `tofu plan` y `tofu apply`.
4. GitOps: haz commit/push y espera sincronización de Flux (o fuerza reconcile).

### Estructura del Servicio en K8s

Cuando agregues un nuevo servicio, asegúrate de que exista en tu clúster y de usar el DNS interno correcto:

```yaml
# El formato es: http://SERVICIO.NAMESPACE.svc.cluster.local:PUERTO
# Ejemplos:
- hostname: app.example.com
  service: http://app.default.svc.cluster.local:8080

- hostname: api.example.com
  service: http://api-backend.namespace.svc.cluster.local:3000

- hostname: admin.example.com
  service: http://admin-panel.monitoring.svc.cluster.local:9090
```

## Troubleshooting

### 1) Revisar logs

```bash
kubectl logs deploy/cloudflared -n cloudflared
```

### 2) Reiniciar deployment

```bash
kubectl rollout restart deploy/cloudflared -n cloudflared
kubectl rollout status deploy/cloudflared -n cloudflared
```

### 3) Si DNS resuelve pero no enruta al servicio

Verifica que la regla `ingress` esté en el ConfigMap y que el `service`/puerto exista en Kubernetes.

```bash
kubectl get configmap cloudflared-configmap -n cloudflared -o yaml
kubectl get svc -n <namespace>
kubectl get endpoints -n <namespace> <service>
```

## Referencias

- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Cloudflared Configuration](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/configuration/configuration-file/)
- [Kubernetes Service DNS](https://kubernetes.io/docs/concepts/services-networking/service/#dns)
