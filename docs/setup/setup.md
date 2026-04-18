# Configuración inicial del entorno

Esta guía describe los pasos para instalar y configurar todas las herramientas necesarias.

---

¿Qué vamos a necesitar?

- Descargar todas las herramientas mediante el script `scripts/download-tools.sh`
- Clave age de SOPS + Age para cifrado de secretos
- GitHub token para FluxCD
- Cloudflare API token para OpenTofu y cert-manager
- Tailscale API key para Tailscale-Operator
- OCI credentials para OCI CLI
- Proxmox credential para OpenTofu

### Clave age de SOPS + Age

Para generar un nuevo par de claves age, ejecuta el siguiente comando:

```bash
age-keygen -o age.key
```

> **Nota**: Si hiciste un fork del repositorio, como primer paso vas a tener que generar una clave sops + age, y regenerar todos los secretos del repositorio, cifrándolos con la nueva clave. Para esto, puedes seguir la guía de SOPS + Age en [docs/sops.md](../sops.md).


### GitHub token

Para generar un token de acceso personal en GitHub, sigue estos pasos:
Ve a tu perfil de GitHub y haz clic en "Settings". En la barra lateral izquierda, selecciona "Developer settings", luego "Personal access tokens" y finalmente "Fine-grained tokens". Haz clic en "Generate new token" y selecciona los permisos necesarios para FluxCD:
- **Repository access:** Only select repositories: <repository_name>
- **Permissions:**
  - Content: Read and write access
  - Metadata: Read access

### Cloudflare API token
Para generar un token de API en Cloudflare, sigue estos pasos:
Inicia sesión en tu cuenta de Cloudflare y haz clic en "My Profile". Luego, selecciona "API Tokens" en la barra lateral izquierda y haz clic en "Create Token". Personaliza los permisos para incluir:
- **Tunnel Cloudflare**: Cuenta - Editar
- **Zero Trust**: Zona - Editar
- **DNS**: Zona - Editar

### Tailscale API key
Para generar una clave de API en Tailscale, sigue estos pasos:
Inicia sesión en tu cuenta de Tailscale y ve a la sección "Admin Console". Luego, haz clic en "Settings" y selecciona "Trust credentials". Haz clic en "+ Credential" y elige OAuth 2.0 Client Credentials. Asigna un nombre a la credencial y selecciona los siguientes permisos:
 - **General**:
  - **Policy File**: Read Write
  - **Services**: Read Write
  - **Tags**: k8s-operator (es posible que necesites crear esta etiqueta en la sección "Tags" antes de asignarla a la credencial)
- **Devices**:
  - **Core**: Read Write
  - **Tags**: k8s-operator
  - **Routes**: Read Write
- **Keys**:
  - **Auth Keys**: Read Write
  - **Tags**: k8s-operator
  - **OAuth Keys** Read Write
Copia el Client ID y Client Secret generados, ya que los necesitarás para configurar el Tailscale Operator en tu clúster de Kubernetes.

### OCI credentials
Para generar las credenciales de OCI, vamos a utilizar el cliente por línea de comandos. Para ello, ejecuta el siguiente comando:

```bash
source scripts/quantum-env.sh && oci setup config
```

Durante el asistente se solicitarán:
- Ruta del archivo de configuración (la ruta por defecto es `~/.oci/config`)
- User OCID (lo puedes encontrar en la sección "User Settings" de la consola de OCI)
- Tenancy OCID (lo puedes encontrar en la sección "Tenancy Details" de la consola de OCI)
- Región (lo puedes encontrar en la sección "Region" de la consola de OCI)

Luego de completar el asistente, se generará un par de claves. La clave pública debe ser cargada en la consola de OCI, en la sección "User Settings" -> "API Keys". La clave privada se guardará en la ruta especificada durante el asistente (por defecto `~/.oci/oci_api_key.pem`).

También necesitaremos una `Customer Secret Key` para usar Object Storage mediante la API compatible con S3, ya que OpenTofu utiliza ese endpoint como backend remoto. Para crearla, ejecuta el siguiente comando reemplazando los valores por los de tu usuario:

```bash
oci iam customer-secret-key create \
  --user-id "<USER_OCID>" \
  --display-name "opentofu-backend"
```

Guarda el `id`, el `key` y el `secret` devueltos por OCI. Estos valores se utilizarán luego como credenciales del backend S3 en la configuración de OpenTofu.

También puedes crear desde aquí el bucket que OpenTofu usará como backend remoto:

```bash
source scripts/quantum-env.sh && bash scripts/create-state-bucket.sh
```

> **Nota**: El script crea el bucket en OCI Object Storage y muestra el valor de `s3_endpoint`, que luego se usa en `config/opentofu/terraform.tfvars`.

### Proxmox credential

TODO



## OpenTofu

Una vez que tengas todas las credenciales de los puntos anteriores, seguiremos con la configuración de OpenTofu.

Luego, copiamos el archivo de variables de ejemplo para OpenTofu:

```bash
cp config/opentofu/terraform.tfvars.example config/opentofu/terraform.tfvars
```
Y reemplazamos los valores de las variables en `config/opentofu/terraform.tfvars` con las credenciales y configuraciones correspondientes.

```yaml
# OCI
region          = "<REGION>"
compartment_id  = "<COMPARTMENT_OCID>"
tenancy_id      = "<TENANCY_OCID>"
s3_endpoint     = "<S3_ENDPOINT>"

# Retención de backups - políticas de ciclo de vida del bucket
archive_after_days = 7
delete_after_days  = 30

# Tailscale
tailscale_oauth_client_id     = "<TAILSCALE_OAUTH_CLIENT_ID>"
tailscale_oauth_client_secret = "<TAILSCALE_OAUTH_CLIENT_SECRET>"
tailscale_tailnet             = "<TAILSCALE_TAILNET>"
tailscale_internal_subnet     = "<TAILSCALE_INTERNAL_SUBNET>"

# Cloudflare
cloudflare_api_token  = "<CLOUDFLARE_API_TOKEN>"
cloudflare_enabled    = true
cloudflare_account_id = "<CLOUDFLARE_ACCOUNT_ID>"
cloudflare_zone_id    = "<CLOUDFLARE_ZONE_ID>"
cloudflare_domain_name = "<CLOUDFLARE_DOMAIN_NAME>"

# proxmox
proxmox_endpoint              = "<PROXMOX_ENDPOINT>"
proxmox_api_token             = "<PROXMOX_API_TOKEN>"
proxmox_ssh_private_key_path  = "<PROXMOX_SSH_PRIVATE_KEY_PATH>"
```

Ejecutamos los siguientes comandos para inicializar y aplicar la configuración de OpenTofu:

```bash
source scripts/quantum-env.sh
tofu init
tofu plan
tofu apply
```

Si todo salió bien, OpenTofu desplegará los recursos en OCI, configurará el túnel de Tailscale, configurará los registros DNS en Cloudflare y aprovisionará las máquinas virtuales en Proxmox.

Como parte del apply, OpenTofu nos dará una serie de outputs que podemos obtener de la siguiente manera:


**Tailscale**:
Para configurar tailscale-operator en el clúster de Kubernetes, necesitamos obtener el `tailscale_operator_oauth_client_secret` generado por OpenTofu. Podemos obtener este valor ejecutando el siguiente comando:
```bash
tofu output -raw tailscale_operator_oauth_client_secret
```
Además, en el output de OpenTofu se mostrará el valor de `tailscale_oauth_client_id`, que también es necesario para la configuración del operador.

**Cloudflare** tunnel ID y tunnel name:

Para configurar el túnel de Cloudflare, necesitamos obtener el `cloudflare_tunnel_token_secret_json` generado por OpenTofu. Podemos obtener este valor ejecutando el siguiente comando:
```bash
tofu output -raw cloudflare_tunnel_token_secret_json
```
Además, en el output de OpenTofu se mostrará el valor de `cloudflare_tunnel_id` que también es necesario para la configuración.


## Configuración del entorno

### Configurar variables de entorno

El script `quantum-env.sh` contiene las configuraciones necesarias para el entorno local:

```bash
source scripts/quantum-env.sh
```

> **Nota**: Edita este archivo para configurar IPs, direcciones MAC y otros parámetros específicos de tu entorno.

## Configuración del clúster

### Crear archivo de configuración del clúster

Crea el archivo `config/quantum-talos/cluster-config.yaml` con la configuración específica del clúster:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-config
  namespace: flux-system
data:
  ADMIN_EMAIL: admin@example.com
  DOMAIN: lab.example.com
```

> **Nota**: Ajusta los valores de `ADMIN_EMAIL` y `DOMAIN` según tu entorno.

## 🚨 Alternativa a Proxmox 🚨

Si no vas a aprovisionar nodos con Proxmox mediante OpenTofu, puedes crear las máquinas virtuales manualmente con QEMU/KVM.

### Requisitos previos

Antes de comenzar, asegúrate de tener instaladas las siguientes herramientas de virtualización:

- [`qemu-kvm`](https://www.qemu.org/) - Virtualización con QEMU/KVM
- [`virt-install`](https://linux.die.net/man/1/virt-install) - Herramienta para crear VMs
- [`libvirt`](https://libvirt.org/) - API de virtualización
- [`genisoimage`](https://linux.die.net/man/1/genisoimage) - Creación de imágenes ISO

### Descargar la imagen de Talos

Descarga la imagen ISO de Talos Linux desde Factory:

```bash
# Descargar imagen Talos desde Factory
wget -O $HOME/qemu/images/talos-v${TALOS_VERSION}.iso \
  "https://factory.talos.dev/image/${SCHEMATIC_ID}/v${TALOS_VERSION}/nocloud-arm64.iso"
```

> **Nota**: El Schematic ID y la versión de Talos están definidos en el archivo `quantum-env.sh`. La imagen se guarda como `talos-v${TALOS_VERSION}-nocloud-arm64.iso` en `$HOME/qemu/images/`.

### Crear máquinas virtuales

#### Crear VM con el script automatizado

El script `vm-create-qemu.sh` facilita la creación de VMs. Los parámetros obligatorios son:

- **`-i|--image`**: Ruta a la imagen base
- **`-t|--target-dir`**: Directorio donde se almacenará la VM

#### Crear nodo Control Plane (nova)

```bash
sh scripts/vm-create-qemu.sh \
  -n nova \
  -c 2 \
  -m 2048 \
  --net bridge \
  --bridge br0 \
  --mac "$CONTROL_PLANE_MAC" \
  -i $HOME/qemu/images/talos-v${TALOS_VERSION}.iso \
  -t $HOME/qemu/vm
```

#### Crear nodo Worker (quark)

```bash
sh scripts/vm-create-qemu.sh \
  -n quark \
  -c 2 \
  -m 2048 \
  --net bridge \
  --bridge br0 \
  --mac "$WORKER_MAC" \
  -i $HOME/qemu/images/talos-v${TALOS_VERSION}.iso \
  -t $HOME/qemu/vm
```

