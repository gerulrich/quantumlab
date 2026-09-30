# Talos

Talos Linux es un sistema operativo de código abierto diseñado exclusivamente para ejecutar Kubernetes. Reemplaza el sistema operativo tradicional por una imagen inmutable y mínima, sin shell ni acceso SSH; toda la administración se realiza a través de su API con `talosctl`. Esto reduce significativamente la superficie de ataque y simplifica las actualizaciones del clúster.

### 📝 Actualización y mantenimiento

Para mantener el clúster actualizado con la última versión de Talos Linux, sigue estos pasos:

```bash
# Actualizar la configuración de Talos
talosctl upgrade --nodes $CONTROL_PLANE_IP --image $TALOS_IMAGE
talosctl reboot --mode powercycle -n $CONTROL_PLANE_IP

kubectl cordon quark
kubectl drain quark --ignore-daemonsets --delete-emptydir-data
talosctl upgrade --nodes $WORKER1_IP --image $TALOS_IMAGE
talosctl reboot --mode powercycle -n $WORKER1_IP
kubectl uncordon quark


kubectl cordon boson
kubectl drain boson --ignore-daemonsets --delete-emptydir-data
talosctl upgrade --nodes $WORKER2_IP --image $TALOS_IMAGE
talosctl reboot --mode powercycle -n $WORKER2_IP
kubectl uncordon boson


kubectl cordon pulsar
kubectl drain pulsar --ignore-daemonsets --delete-emptydir-data
talosctl upgrade --nodes $WORKER3_IP --image $TALOS_IMAGE
talosctl reboot --mode powercycle -n $WORKER3_IP
kubectl uncordon pulsar

# Verificar la versión actual de Talos y Kubernetes
talosctl version
kubectl version
```

### ⬆️ Actualizar la versión de Kubernetes

Para actualizar Kubernetes a una nueva versión, primero ejecuta una simulación para validar el proceso:

```bash
# Validar la actualización sin aplicar cambios (dry-run)
talosctl --nodes $CONTROL_PLANE_IP -e $CONTROL_PLANE_IP upgrade-k8s --to 1.37.2 --dry-run

# Aplicar la actualización de Kubernetes
talosctl --nodes $CONTROL_PLANE_IP -e $CONTROL_PLANE_IP upgrade-k8s --to 1.37.2
```

---

Para más información, consulta la [documentación oficial de Talos Linux](https://docs.siderolabs.com/talos).
