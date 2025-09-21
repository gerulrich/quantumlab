# Instalación del clúster Talos

Esta guía detalla los pasos necesarios para instalar un clúster de Kubernetes utilizando Talos Linux. En este ejemplo, se implementa un entorno con QEMU que consta de un nodo **control plane** y otro nodo **worker**.

> ⏱️ Tiempo estimado de implementación: 20-30 minutos

---

### Requisitos previos

Asegúrate de tener las siguientes herramientas instaladas en tu máquina local antes de comenzar:

- [`talosctl`](https://github.com/siderolabs/talos/releases) - CLI para administrar nodos Talos
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
export SCHEMATIC_ID=00514c155d2b32b2fa9b316b130735ef2a9f8f0f7a24e328b12d8a990b550a49
export TALOS_IMAGE=factory.talos.dev/installer/${SCHEMATIC_ID}:v1.11.1
export DISK=/dev/vda
```

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

> ⚠️ Asegúrate de que los nodos hayan arrancado con la imagen Talos y estén accesibles por red antes de continuar.

#### Configurar nodo Control Plane

```bash
talosctl apply-config --insecure --file talos/controlplane.yaml \
    --nodes $CONTROL_PLANE_IP \
    --config-patch @talos/hostname.nova.patch.yaml
```

#### Configurar nodo Worker

```bash
talosctl apply-config --insecure --file talos/worker.yaml \
    --nodes $WORKER_IP \
    --config-patch @talos/hostname.quark.patch.yaml
```

> Para clústeres más grandes, repite el proceso en cada nodo usando el archivo de configuración correspondiente.

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
# Verificar que los nodos están registrados y listos
kubectl get nodes
# Deberías ver todos los nodos con STATUS "Ready"

# Monitorear los componentes del sistema en tiempo real
watch -w -t -n 2 kubectl get all -A
# Verifica que los pods del sistema estén en estado "Running"
```

### Verificar el estado de los nodos con talosctl

También puedes verificar el estado de los nodos directamente desde el dashboard de Talos:

```bash
# Ver el dashboard de los nodos (ambos deberían mostrar "Ready", Ctrl+C para salir del dashboard)
talosctl dashboard --nodes $CONTROL_PLANE_IP

talosctl dashboard --nodes $WORKER_IP
```

> Los nodos deben aparecer en estado "Ready" tanto en el output de `kubectl get nodes` como en el dashboard de Talos.

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

