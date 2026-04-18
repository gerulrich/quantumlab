
# OpenTofu

OpenTofu es la capa de infraestructura como código del homelab. En este repositorio se usa para gestionar recursos de OCI, Tailscale, Cloudflare y Proxmox de forma declarativa, con estado remoto en Object Storage compatible con S3.

## Organización de archivos

La configuración vive en `config/opentofu/` y se divide por dominio:

- `providers.tf`: backend `s3`, versiones de providers y configuración de `oci`, `tailscale`, `cloudflare` y `proxmox`.
- `variables.tf`: contrato de entrada del módulo (credenciales, identificadores y flags como `cloudflare_enabled`).
- `buckets.tf`: bucket de backups en OCI, política IAM y lifecycle de archivado/borrado.
- `tailscale.tf`: política ACL de Tailscale y OAuth client para `tailscale-operator`.
- `cloudflare.tf`: túnel Zero Trust y registros DNS asociados.
- `proxmox.tf`: descarga de imagen Talos, snippet cloud-init y VM worker en Proxmox.
- `outputs.tf`: salidas operativas para consumo posterior (endpoints, IDs y secretos).
- `terraform.tfvars`: valores locales reales del entorno.
- `terraform.tfvars.example`: plantilla base para crear `terraform.tfvars`.
- `tailscale-policy.hujson.tftpl`: plantilla HUJSON para generar ACL dinámicas de Tailscale.

## Recursos gestionados

### OCI

- **BUCKET: `backups-homelab`** (`oci_objectstorage_bucket.backups`)
  Repositorio de backups en Object Storage. Está definido sin acceso público y en tier Standard.
- **POLITICA IAM DE LIFECYCLE** (`oci_identity_policy.objectstorage_lifecycle_service`)
  Habilita al servicio de Object Storage para ejecutar acciones automáticas de archivado y eliminación sobre el bucket.
- **POLITICA DE RETENCION** (`oci_objectstorage_object_lifecycle_policy.backups_policy`)
  Mantiene objetos activos durante `archive_after_days`, luego los mueve a Archive, y después de `delete_after_days` los elimina automáticamente.

### Tailscale

- **ACL POLICY** (`tailscale_acl.policy`)
  Aplica la política de red del tailnet a partir de la plantilla `tailscale-policy.hujson.tftpl`, incluyendo tags, grants y autoapprovers.
- **OAUTH CLIENT: `talos tailscale operator - opentofu`** (`tailscale_oauth_client.k8s_operator`)
  Credenciales usadas por `tailscale-operator` para registrar nodos, administrar rutas y operar dispositivos en Tailscale.

### Cloudflare

- **TUNNEL SECRET** (`random_password.tunnel_secret`)
  Secreto criptográfico base para autenticar el túnel de Cloudflare.
- **ZERO TRUST TUNNEL: `quantum-k8s-tunnel`** (`cloudflare_zero_trust_tunnel_cloudflared.quantum`)
  Túnel principal para exponer servicios del clúster sin abrir puertos públicos. Se crea solo si `cloudflare_enabled` está activo.
- **DNS ROUTES DEL TUNNEL** (`cloudflare_dns_record.tunnel_routes`)
  Registros CNAME proxied que apuntan a `<tunnel_id>.cfargotunnel.com`, uno por cada hostname declarado.

### Proxmox

- **TALOS ISO** (`proxmox_download_file.talos_disk_image`)
  Descarga la imagen ISO de Talos en el datastore local de Proxmox para usarla como medio de arranque.
- **CLOUD-INIT SNIPPET WORKER** (`proxmox_virtual_environment_file.talos_worker_cloud_init`)
  Carga la configuración inicial del nodo worker como snippet reutilizable.
- **VM WORKER: `talos-boson`** (`proxmox_virtual_environment_vm.talos_boson_vm`)
  Define y aprovisiona la VM worker con hardware, red, disco y orden de arranque declarados en código.

## Variables clave

Las variables están centralizadas en `variables.tf` y se completan en `terraform.tfvars`.

- OCI y backend: `region`, `compartment_id`, `tenancy_id`, `s3_endpoint`, `s3_access_key_id`, `s3_secret_access_key`.
- Retención de backups: `archive_after_days`, `delete_after_days`.
- Tailscale: `tailscale_oauth_client_id`, `tailscale_oauth_client_secret`, `tailscale_tailnet`, `tailscale_internal_subnet`.
- Cloudflare: `cloudflare_enabled`, `cloudflare_api_token`, `cloudflare_account_id`, `cloudflare_zone_id`, `cloudflare_domain_name`.
- Proxmox: `proxmox_endpoint`, `proxmox_api_token`, `proxmox_ssh_private_key_path`.

## Comandos básicos

```bash
source scripts/quantum-env.sh

tofu init
tofu plan
tofu apply
```

Para destruir recursos declarados en el módulo:

```bash
source scripts/quantum-env.sh
tofu destroy
```

## Consultar outputs

Ver todas las salidas:

```bash
source scripts/quantum-env.sh
tofu output
```

Obtener un output puntual:

```bash
source scripts/quantum-env.sh
tofu output s3_endpoint
tofu output cloudflare_tunnel_id
```

Obtener salidas sensibles en formato crudo:

```bash
source scripts/quantum-env.sh
tofu output -raw tailscale_operator_oauth_client_secret
tofu output -raw cloudflare_tunnel_token_secret_json
```

## Troubleshooting

### 1) Revisar estado y recursos del state

```bash
source scripts/quantum-env.sh
tofu state list
```

### 2) Validar configuración antes de aplicar

```bash
source scripts/quantum-env.sh
tofu fmt -check
tofu validate
```

### 3) Si cambia backend o credenciales S3

```bash
source scripts/quantum-env.sh
tofu init -reconfigure
```

## Referencias

- [OpenTofu Documentation](https://opentofu.org/docs/)
- [OCI Object Storage (S3 Compatibility API)](https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/s3compatibleapi.htm)
- [Cloudflare Zero Trust Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Tailscale ACLs](https://tailscale.com/kb/1018/acls)

