# Configuración inicial del entorno

Esta guía describe los pasos para configurar el entorno de laboratorio Kubernetes usando QEMU/KVM.

---

## 📦 Requisitos previos

Antes de comenzar, asegúrate de tener instaladas las siguientes herramientas de virtualización:

- [`qemu-kvm`](https://www.qemu.org/) - Virtualización con QEMU/KVM
- [`virt-install`](https://linux.die.net/man/1/virt-install) - Herramienta para crear VMs
- [`libvirt`](https://libvirt.org/) - API de virtualización
- [`genisoimage`](https://linux.die.net/man/1/genisoimage) - Creación de imágenes ISO

---

## 0️⃣ Descarga de la imagen ISO

### Descargar la imagen de Talos

Antes de crear las VMs, descarga la imagen ISO de Talos Linux desde Factory:

```bash
# Descargar imagen Talos v1.11.6 para arquitectura ARM64
wget -O talosv1.11.6.iso 'https://factory.talos.dev/image/a2e824fa8b6d72b70f9076cebd483a76cd56a07a0a81372611a8ed6fe3b6b95e/v1.11.6/nocloud-arm64.iso'
```

> **Nota**: Guarda la imagen en el directorio `$HOME/qemu/images/` o ajusta la ruta en los comandos de creación de VMs.

---

## 1️⃣ Configuración del entorno

### 1.1 Configurar variables de entorno

El script `quantum-env.sh` contiene las configuraciones necesarias para el entorno local:

```bash
source scripts/quantum-env.sh
```

> **Nota**: Edita este archivo para configurar IPs, direcciones MAC y otros parámetros específicos de tu entorno.

---

## 2️⃣ Creación de máquinas virtuales

### 2.1 Crear VM con el script automatizado

El script `vm-create-qemu.sh` facilita la creación de VMs. Los parámetros obligatorios son:

- **`-i|--image`**: Ruta a la imagen base
- **`-t|--target-dir`**: Directorio donde se almacenará la VM

### 2.2 Crear nodo master de Talos

```bash
sh scripts/vm-create-qemu.sh \
  -n talos-test-m \
  -c 2 \
  -m 2048 \
  --net bridge \
  --bridge br0 \
  --mac "$CONTROL_PLANE_MAC" \
  -i $HOME/qemu/images/talosv1.11.6.iso \
  -t $HOME/qemu/vm
```

### 2.3 Crear nodo worker de Talos

```bash
sh scripts/vm-create-qemu.sh \
  -n talos-test-w \
  -c 2 \
  -m 2048 \
  --net bridge \
  --bridge br0 \
  --mac "$WORKER_MAC" \
  -i $HOME/qemu/images/talosv1.11.6.iso \
  -t $HOME/qemu/vm
```

---

## 3️⃣ Configuración del clúster

### 3.1 Crear archivo de configuración del clúster

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

---

## 4️⃣ Instalación de herramientas CLI

### 4.1 Descargar Cilium CLI

```bash
sh scripts/download-cilium.sh
```

### 4.2 Instalar kubectl

```bash
sh scripts/download-kubectl.sh
```

### 4.3 Instalar Flux CLI

```bash
sh scripts/download-flux.sh
```

### 4.4 Instalar Helm

```bash
sh scripts/download-helm.sh
```

> **Nota**: Todas las herramientas se instalan en `$PWD/bin` que está incluido en el `PATH` al hacer `source scripts/quantum-env.sh`.

