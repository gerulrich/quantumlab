# Instalación del clúster Talos

Esta guía detalla los pasos necesarios para instalar un clúster de Kubernetes utilizando Talos Linux. En este homelab se implementa un entorno híbrido que combina infraestructura local y en la nube:

## Arquitectura del Homelab

- **Control Plane local**: 1 VM con QEMU (nova)
- **Workers locales**: 1 VM con QEMU (quark)
- **Workers en OCI**: 2 VMs en Oracle Cloud Infrastructure (photon, vortex)

Este diseño híbrido permite aprovechar tanto los recursos locales como la capacidad de cómputo en la nube, creando un entorno distribuido y resiliente.

> ⏱️ Tiempo estimado de implementación: 30-45 minutos

---

### Requisitos previos

Asegúrate de tener las siguientes herramientas instaladas en tu máquina local antes de comenzar:

- [`talosctl`](https://www.talos.dev/latest/introduction/getting-started/installation/) - CLI para administrar nodos Talos
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/) - CLI para interactuar con Kubernetes

---

## 1. 🧰 Preparación inicial

### Descargar la imagen de Talos

Accede a [Talos Image Factory](https://factory.talos.dev/) y descarga la imagen **no cloud** siguiendo esta ruta: 
**Cloud Server** → **select version** → **No Cloud**

Al completar la descarga, asegúrate de guardar los siguientes datos importantes:

- **Schematic ID** - Identificador único de la configuración de la imagen
- **Customization YAML** - Archivo con las personalizaciones aplicadas
- **Ruta de la imagen** - Ubicación donde se guardó la imagen

---

## 2. ⚙️ Configuración inicial

### Configurar variables de entorno

Define las variables que utilizaremos durante todo el proceso:

```bash
export CONTROL_PLANE_IP=192.168.0.125
export WORKER_IP=192.168.0.230
export WORKER_IP_OCI_1=<public_ip_photon>  # Photon - Reemplazar con IP pública real
export WORKER_IP_OCI_2=<public_ip_vortex>  # Vortex - Reemplazar con IP pública real
export SCHEMATIC_ID=00514c155d2b32b2fa9b316b130735ef2a9f8f0f7a24e328b12d8a990b550a49
export TALOS_IMAGE=factory.talos.dev/installer/${SCHEMATIC_ID}:v1.11.1
export DISK=/dev/vda
```

> 📝 **Importante**: Reemplaza `<public_ip_photon>` y `<public_ip_vortex>` con las direcciones IP públicas reales de tus instancias en OCI.

### Obtener el Schematic ID

Si no registraste el Schematic ID, puedes obtenerlo con:

```bash
curl -X POST --data-binary @talos/customizations.yaml https://factory.talos.dev/schematics
```

### Identificar la unidad de disco para la instalación

Si necesitas verificar o cambiar la unidad de disco configurada:

```bash
talosctl get disks --insecure --nodes $CONTROL_PLANE_IP
# Confirma que DISK=/dev/vda sea correcto para tu entorno
```

---

## 3. 📦 Generar archivos de configuración

Genera los archivos YAML necesarios para configurar todos los nodos del clúster:

```bash
talosctl gen config quantum https://$CONTROL_PLANE_IP:6443 \
    --output-dir talos \
    --install-image $TALOS_IMAGE \
    --install-disk $DISK
```

> 📝 Este comando crea varios archivos en el directorio `talos/`, incluyendo controlplane.yaml, worker.yaml y talosconfig.

---

## 4. 🚀 Aplicar configuración a los nodos

> ⚠️ Asegúrate de que todos los nodos (locales y en OCI) hayan arrancado con la imagen Talos y estén accesibles por red antes de continuar.

#### Configurar nodo Control Plane (Local)

```bash
talosctl apply-config --insecure --file talos/controlplane.yaml \
    --nodes $CONTROL_PLANE_IP \
    --config-patch @talos/hostname.nova.patch.yaml
```

#### Configurar Workers Locales

```bash
# Worker local: quark
talosctl apply-config --insecure --file talos/worker.yaml \
    --nodes $WORKER_IP \
    --config-patch @talos/hostname.quark.patch.yaml
```

#### Configurar Workers en OCI

```bash
# Worker OCI: photon
talosctl apply-config --insecure --file talos/worker.yaml \
    --nodes $WORKER_IP_OCI_1 \
    --config-patch @talos/hostname.photon.patch.yaml

# Worker OCI: vortex
talosctl apply-config --insecure --file talos/worker.yaml \
    --nodes $WORKER_IP_OCI_2 \
    --config-patch @talos/hostname.vortex.patch.yaml
```

> 📡 **Configuración de red en OCI**: Asegúrate de configurar las reglas de Security Groups para permitir el tráfico de Kubespan y la configuración inicial de cada instancia (puertos 50000, 6443, 51820).

---

## 5. 🔧 Inicialización y configuración del clúster

### Configurar cliente talosctl

```bash
export TALOSCONFIG="talos/talosconfig"
talosctl config endpoint $CONTROL_PLANE_IP
talosctl config node $CONTROL_PLANE_IP
```

### Inicializar componentes de Kubernetes

```bash
talosctl bootstrap
```

> Este comando inicia el proceso de bootstrap en el nodo Control Plane, que configurará etcd y los componentes del plano de control de Kubernetes.

### Configurar acceso a kubectl

```bash
talosctl kubeconfig .
export KUBECONFIG=$PWD/kubeconfig
```

---

## 6. ✅ Verificación del clúster

Ejecuta los siguientes comandos para verificar que el clúster está funcionando correctamente:

```bash
# Verificar que todos los nodos están registrados y listos
kubectl get nodes
# Deberías ver todos los nodos (nova, quark, photon, vortex) con STATUS "Ready"

# Monitorear los componentes del sistema en tiempo real
watch -w -t -n 2 kubectl get all -A
# Verifica que los pods del sistema estén en estado "Running"
```

### Verificar el estado de los nodos con talosctl

También puedes verificar el estado de los nodos directamente desde el dashboard de Talos:

```bash
# Ver el dashboard del control plane
talosctl dashboard --nodes $CONTROL_PLANE_IP

# Ver el dashboard de los workers locales
talosctl dashboard --nodes $WORKER_IP

# Ver el dashboard de los workers en OCI
talosctl dashboard --nodes $WORKER_IP_OCI_1
talosctl dashboard --nodes $WORKER_IP_OCI_2
```

> Los nodos deben aparecer en estado "Ready" tanto en el output de `kubectl get nodes` como en el dashboard de Talos.

### Etiquetar nodos por ubicación

Para una mejor organización y posible scheduling basado en ubicación, etiqueta los nodos según su localización:

```bash
# Etiquetar nodos locales
kubectl label node nova location=local
kubectl label node quark location=local

# Etiquetar nodos en OCI
kubectl label node photon location=oci
kubectl label node vortex location=oci
```

Verifica las etiquetas aplicadas:

```bash
kubectl get nodes --show-labels
```

> 🏷️ Estas etiquetas te permitirán usar node selectors o affinity rules para desplegar workloads específicamente en nodos locales o en la nube según tus necesidades.

---

## 7. 📝 Mantenimiento del clúster

Para futuras operaciones de mantenimiento, estos comandos serán útiles:

```bash
# Actualizar la configuración de Talos
talosctl upgrade --nodes $NODE_IP --image $NEW_TALOS_VERSION

# Reiniciar un nodo si es necesario
talosctl reboot --nodes $NODE_IP

# Verificar la versión actual de Talos y Kubernetes
talosctl version
kubectl version
```

Para más información, consulta la [documentación oficial de Talos Linux](https://www.talos.dev/).

