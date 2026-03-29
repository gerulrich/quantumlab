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

## 0️⃣ Configuración del entorno

### Configurar variables de entorno

El script `quantum-env.sh` contiene las configuraciones necesarias para el entorno local:

```bash
source scripts/quantum-env.sh
```

> **Nota**: Edita este archivo para configurar IPs, direcciones MAC y otros parámetros específicos de tu entorno.

---

## 1️⃣ Descarga de la imagen ISO

### Descargar la imagen de Talos

Descarga la imagen ISO de Talos Linux desde Factory:

```bash
# Descargar imagen Talos desde Factory
wget -O $HOME/qemu/images/talos-v${TALOS_VERSION}.iso \
  "https://factory.talos.dev/image/${SCHEMATIC_ID}/v${TALOS_VERSION}/nocloud-arm64.iso"
```

> **Nota**: El Schematic ID y la versión de Talos están definidos en el archivo `quantum-env.sh`. La imagen se guarda como `talos-v${TALOS_VERSION}-nocloud-arm64.iso` en `$HOME/qemu/images/`.

---

## 2️⃣ Creación de máquinas virtuales

### 2.1 Crear VM con el script automatizado

El script `vm-create-qemu.sh` facilita la creación de VMs. Los parámetros obligatorios son:

- **`-i|--image`**: Ruta a la imagen base
- **`-t|--target-dir`**: Directorio donde se almacenará la VM

### 2.2 Crear nodo Control Plane (nova)

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

### 2.3 Crear nodo Worker (quark)

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

### Descargar todas las herramientas necesarias

Ejecuta el script de descarga para instalar todas las herramientas CLI necesarias:

```bash
# Descargar e instalar Cilium, Flux, Helm y kubectl
sh scripts/download-tools.sh
```

Este script descarga e instala automáticamente:
- **Cilium CLI** - Administración del CNI Cilium
- **Flux CLI** - GitOps con FluxCD
- **Helm** - Gestor de paquetes de Kubernetes
- **kubectl** - CLI de Kubernetes

> **Nota**: Todas las herramientas se instalan en `$PWD/bin`, que está incluido en el `PATH` al hacer `source scripts/quantum-env.sh`.

---

## ✅ Siguientes pasos de setup

Continúa con estos documentos para completar la instalación base:

1. [Instalación del clúster Talos](talos-bootstrap.md)
2. [Configuración de Cilium y API Gateway](cilium-api-gateway.md)
3. [Flux CD con SOPS y Age](bootstrap-fluxcd-sops-age.md)

## 📖 Documentación adicional

Cuando el setup base esté listo, revisa documentación complementaria en `docs/`:

- [Talos](../talos.md)
- [Cert-Manager](../cert-manager.md)
- [Cilium](../cilium.md)
- [Flux CD](../fluxcd.md)
- [SOPS](../sops.md)
- [MQTT con Mosquitto](../mqtt.md)
- [Netboot.xyz en Kubernetes](../netbootxyz.md)
- [Renovate para actualizaciones automáticas](../renovate.md)

