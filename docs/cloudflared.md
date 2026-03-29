# Cloudflared - Túnel de Cloudflare

Documentación para gestionar el túnel de Cloudflare (cloudflared) que expone servicios del cluster a través de un túnel seguro sin necesidad de puertos abiertos.

## Introducción al Túnel

El túnel de Cloudflare (`quantum-tunnel`) se ejecuta como un deployment en Kubernetes y crea una conexión persistente hacia los servidores de Cloudflare. Esto permite exponer servicios internos del cluster sin abrir puertos en el firewall.

**Ventajas:**
- No requiere puertos abiertos públicamente
- SSL/TLS automático
- Control de acceso y analytics

## Gestión del Túnel desde CLI

El túnel es gestionado principalmente desde la **CLI de Cloudflare** (`wrangler` o `cloudflare-cli`). Los comandos se ejecutan fuera del cluster para crear y configurar el túnel.

### Comandos Principales del Túnel

**Ver estado del túnel:**
```bash
cloudflare tunnel list
```

**Ver credenciales del túnel:**
```bash
cloudflare tunnel token quantum-tunnel
```

**Crear un nuevo túnel (si fuera necesario):**
```bash
cloudflare tunnel create quantum-tunnel
```

**Ver rutas (ingresos) del túnel:**
```bash
cloudflare tunnel route list quantum-tunnel
```

## Agregar un Nuevo Ingreso (Hostname/Servicio)

Los nuevos ingresos se agregan modificando el ConfigMap en el repositorio de Flux.

**1. Edita el archivo de configuración del ConfigMap:**

```bash
# Edita el archivo de configuración base en el repositorio
vim apps/base/cloudflared/config-map.yaml
```

**2. Agrega una nueva línea en la sección `ingress`:**

```yaml
data:
  config.yaml: |
    tunnel: quantum-tunnel
    credentials-file: /etc/cloudflared/creds/credentials.json
    metrics: 0.0.0.0:2000
    no-autoupdate: true
    ingress:
    - hostname: ng.${DOMAIN}
      service: http://nginx.nginx.svc.cluster.local:80
    - hostname: photos.${DOMAIN}
      service: http://photoprism.photoprism.svc.cluster.local:2342
    - hostname: newservice.${DOMAIN}                          # ← NUEVO INGRESO
      service: http://newservice.namespace.svc.cluster.local:PORT  # ← NUEVO INGRESO
    - service: http_status:404
```

**3. Sube los cambios a la rama principal mediante un Pull Request:**

Una vez realizado el commit en tu rama local, crea un Pull Request para que los cambios se revisen e integren en la rama principal del repositorio.

**4. Una vez que el PR es aprobado y mergeado, Flux sincronizará automáticamente los cambios:**

```bash
flux reconcile source git flux-system
flux reconcile kustomization flux-system
```

**5. Verifica que el deployment se actualizó:**

```bash
kubectl rollout status deployment/cloudflared -n cloudflared
```

### Estructura del Servicio en K8s

Cuando agreguess un nuevo servicio, asegúrate de que exista en tu cluster:

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

## Verificación

### Verificar que el túnel está activo

```bash
kubectl get deployment -n cloudflared
kubectl get pods -n cloudflared
```

### Ver logs del túnel

```bash
kubectl logs -f deployment/cloudflared -n cloudflared
```

### Verificar conectividad a un ingreso

```bash
curl https://ng.${DOMAIN}
curl https://photos.${DOMAIN}
```

## Troubleshooting

### El túnel muestra estado "Disconnected"

Verifica los logs:
```bash
kubectl logs deployment/cloudflared -n cloudflared
```

Reinicia el deployment:
```bash
kubectl rollout restart deployment/cloudflared -n cloudflared
```

### Un ingreso no responde

1. Verifica que el servicio existe y está disponible:
```bash
kubectl get svc -A | grep SERVICIO
kubectl get endpoints -n NAMESPACE SERVICIO
```

2. Verifica la configuración en el ConfigMap:
```bash
kubectl get configmap cloudflared-configmap -n cloudflared -o yaml
```

3. Comprueba que el puerto es correcto en el servicio

### Reiniciar cloudflared

```bash
kubectl delete pod -n cloudflared -l app=cloudflared
```

El deployment creará nuevos pods automáticamente.

## Referencias

- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Cloudflared Configuration](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/configuration/configuration-file/)
- [Kubernetes Service DNS](https://kubernetes.io/docs/concepts/services-networking/service/#dns)
