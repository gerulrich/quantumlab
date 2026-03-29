# Talos

Esta guía reúne operaciones de mantenimiento y comandos de referencia para Talos, separados del flujo principal de setup.

---

## 📝 Mantenimiento del clúster

Para futuras operaciones de mantenimiento, estos comandos son útiles:

```bash
# Actualizar la configuración de Talos
talosctl upgrade --nodes $CONTROL_PLANE_IP --image $TALOS_IMAGE
talosctl reboot --mode powercycle -n $CONTROL_PLANE_IP

talosctl upgrade --nodes $WORKER_IP --image $TALOS_IMAGE
talosctl reboot --mode powercycle -n $WORKER_IP

# Verificar la versión actual de Talos y Kubernetes
talosctl version
kubectl version
```

## ⬆️ Actualizar la versión de Kubernetes

Para actualizar Kubernetes a una nueva versión, primero ejecuta una simulación para validar el proceso:

```bash
# Validar la actualización sin aplicar cambios (dry-run)
talosctl --nodes $CONTROL_PLANE_IP -e $CONTROL_PLANE_IP upgrade-k8s --to 1.34.2 --dry-run

# Aplicar la actualización de Kubernetes
talosctl --nodes $CONTROL_PLANE_IP -e $CONTROL_PLANE_IP upgrade-k8s --to 1.34.2
```

---

Para más información, consulta la [documentación oficial de Talos Linux](https://www.talos.dev/).
