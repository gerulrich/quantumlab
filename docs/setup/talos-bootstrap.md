# Instalación del clúster Talos

Esta guía detalla los pasos necesarios para instalar un clúster de Kubernetes utilizando Talos Linux.

## Arquitectura del Homelab

- **Control Plane local**: 1 VM con QEMU (nova)
- **Workers locales**: 1 VM con QEMU (quark)

Este diseño híbrido permite aprovechar tanto los recursos locales como la capacidad de cómputo en la nube, creando un entorno distribuido y resiliente.

> ⏱️ Tiempo estimado de implementación: 30-45 minutos

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
export TALOS_IMAGE=factory.talos.dev/installer/${SCHEMATIC_ID}:v${TALOS_VERSION}
export DISK=/dev/vda
```

### Obtener el Schematic ID

Si no registraste el Schematic ID, puedes obtenerlo con:

```bash
curl -X POST --data-binary @config/quantum-talos/customizations.yaml https://factory.talos.dev/schematics
```

### Identificar la unidad de disco para la instalación

Si necesitas verificar o cambiar la unidad de disco configurada:

```bash
talosctl get disks --insecure --nodes $CONTROL_PLANE_IP
# Confirma que DISK=/dev/vda sea correcto para tu entorno
```

### Identificar los dispositivos de red:

```bash
talosctl get links  --insecure --nodes $CONTROL_PLANE_IP
```
---

## 3. 📦 Generar archivos de configuración

Genera los archivos YAML necesarios para configurar todos los nodos del clúster:

```bash
talosctl gen config quantum https://$CONTROL_PLANE_IP:6443 \
    --output-dir config/quantum-talos \
    --install-image $TALOS_IMAGE \
    --install-disk $DISK
```

Elimina la configuración de hostname para aplicar el parche por instancia:
```bash
sed -i '/^---$/,/^$/ {
  s/^apiVersion:/# apiVersion:/
  s/^kind: HostnameConfig/# kind: HostnameConfig/
  s/^auto:/# auto:/
}'  config/quantum-talos/worker.yaml

sed -i '/^---$/,/^$/ {
  s/^apiVersion:/# apiVersion:/
  s/^kind: HostnameConfig/# kind: HostnameConfig/
  s/^auto:/# auto:/
}'  config/quantum-talos/controlplane.yaml
```


> 📝 Este comando crea varios archivos en el directorio `config/quantum-talos/`, incluyendo controlplane.yaml, worker.yaml y talosconfig.

---

## 4. 🚀 Aplicar configuración a los nodos

> ⚠️ Asegúrate de que todos los nodos hayan arrancado con la imagen Talos y estén accesibles por red antes de continuar.

#### Configurar nodo Control Plane (Local)

```bash
talosctl apply-config --insecure --file config/quantum-talos/controlplane.yaml \
    --nodes $CONTROL_PLANE_IP \
    --config-patch @config/quantum-talos/hostname.nova.patch.yaml
```

#### Configurar Workers Locales

```bash
# Worker local: quark
talosctl apply-config --insecure --file config/quantum-talos/worker.yaml \
    --nodes $WORKER_IP \
    --config-patch @config/quantum-talos/hostname.quark.patch.yaml
```

---

## 5. 🔧 Inicialización y configuración del clúster

### Configurar cliente talosctl

```bash
export TALOSCONFIG="$PWD/config/quantum-talos/talosconfig"
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

```

> Los nodos deben aparecer en estado "Ready" tanto en el output de `kubectl get nodes` como en el dashboard de Talos.

---

## 📖 Información adicional

Para operaciones de mantenimiento y administración continua de Talos, consulta:

- [Talos](../talos.md)

