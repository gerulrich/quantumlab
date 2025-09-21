# Cilium API Gateway

Esta guía detalla los pasos necesarios para instalar Cilium como CNI y habilitar la API Gateway en un clúster Kubernetes. Cilium proporciona redes seguras y observables para cargas de trabajo nativas de la nube, mientras que la API Gateway permite gestionar el tráfico entrante al clúster.

> ⏱️ Tiempo estimado de implementación: 15-20 minutos

---

## 1. 🗂 Requisitos previos

Asegúrate de tener las siguientes herramientas y componentes instalados antes de comenzar:

- [`helm`](https://helm.sh/docs/intro/install/) - Gestor de paquetes para Kubernetes
- [`cilium`](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/) - CLI de Cilium (opcional, para diagnósticos)

---

## 2. 🔄 Preparar el clúster para Cilium

### Aplicar patch CNI en Talos

Primero, necesitamos configurar Talos para desactivar kube-proxy y configurar el CNI en modo "none", ya que Cilium reemplazará estas funcionalidades:

```bash
# Aplicar el patch a la configuración de Talos
talosctl patch machineconfig -n $CONTROL_PLANE_IP --patch @talos/cni.patch.yaml --endpoints $CONTROL_PLANE_IP --mode=reboot

# Importante: Espera a que todos los nodos reinicien y estén en estado "Ready"
# Puedes verificar el estado desde el dashboard de Talos
talosctl dashboard --nodes $CONTROL_PLANE_IP
```

> ⚠️ No continúes hasta que todos los nodos estén completamente operativos después del reinicio. El clúster puede tardar unos minutos en estabilizarse.

---

## 3. 🧾 Instalar Gateway API

La Gateway API proporciona recursos para configurar enrutamiento, balanceo de carga y más. Esta es una dependencia de Cilium API Gateway:

```bash
# Instalar los CRDs de la Gateway API
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml

# Instalar recursos experimentales (TLS Routes)
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.3.0/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml
```

> 📝 Estos comandos instalan las definiciones de recursos personalizados (CRDs) necesarias para la API Gateway.

---

## 4. 🧩 Instalar Cilium con API Gateway

Instalamos Cilium utilizando Helm para generar el manifiesto y luego lo aplicamos:

```bash
# Agregar el repositorio de Cilium a Helm
helm repo add cilium https://helm.cilium.io/
helm repo update

# Generar el manifiesto de Cilium con las opciones adecuadas
helm template \
    cilium \
    cilium/cilium \
    --version 1.18.2 \
    --namespace kube-system \
    --set ipam.mode=kubernetes \
    --set l2announcements.enabled=true \
    --set l2announcements.leaseDuration="3s" \
    --set l2announcements.leaseRenewDeadline="1s" \
    --set l2announcements.leaseRetryPeriod="500ms" \
    --set k8sClientRateLimit.qps=32 \
    --set k8sClientRateLimit.burst=33 \
    --set kubeProxyReplacement=true \
    --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --set cgroup.autoMount.enabled=false \
    --set cgroup.hostRoot=/sys/fs/cgroup \
    --set k8sServiceHost=localhost \
    --set k8sServicePort=7445 \
    --set gatewayAPI.enabled=true \
    --set gatewayAPI.enableAlpn=true \
    --set gatewayAPI.enableAppProtocol=true \
    --set bgpControlPlane.enabled=true \
    --set externalIPs.enabled=true  \
    --set devices="{eth0,net0}" \
    --api-versions='gateway.networking.k8s.io/v1/GatewayClass' > cilium.yaml

# Aplicar el manifiesto generado
kubectl apply -f cilium.yaml
```

### Monitores el progreso de la instalación

```bash
# Monitorear que todos los pods se inicien correctamente
watch -w -t -n 2 kubectl get all -A
```

> 🔍 Espera a que todos los pods de Cilium estén en estado "Running" antes de continuar con el siguiente paso.

### Eliminar kube-proxy (si aún existe)

```bash
# Verificar si kube-proxy está ejecutándose
kubectl get daemonset kube-proxy -n kube-system 

# Si existe, eliminarlo
kubectl delete daemonset kube-proxy -n kube-system 
```

---

## 5. ✅ Verificar la instalación de Cilium

Es importante comprobar que Cilium está funcionando correctamente antes de continuar:

```bash
# Ejecutar el test de conectividad de Cilium
cilium connectivity test
```

> ⚠️ Si la prueba se queda en estado "Waiting", ejecuta el siguiente comando desde otra terminal:

```bash
kubectl label namespace cilium-test-1 pod-security.kubernetes.io/enforce=privileged
```

Una vez completada la prueba, limpia los recursos creados:

```bash
# Eliminar namespace de prueba
kubectl delete namespace cilium-test-1
```

---

## 6. 🌐 Configurar recursos de red

### Configurar Pool de IPs

Debes crear un pool de IPs para que Cilium pueda asignarlas a los servicios:

```bash
# Aplicar configuración del pool de IPs
kubectl apply -f infrastructure/network/cilium/ip_pool.yaml
```

> ⚠️ Asegúrate de editar `infrastructure/network/cilium/ip_pool.yaml` para que las IPs correspondan a tu red y que no se solapen con las IPs usadas para DHCP.

### Configurar política de anuncio

```bash
# Aplicar la política de anuncio de IPs
kubectl apply -f infrastructure/network/cilium/advert_policy.yaml
```

---

## 7. 🔎 Verificación y resolución de problemas

Para verificar el estado de Cilium y solucionar posibles problemas:

```bash
# Verificar estado de los agentes de Cilium
kubectl -n kube-system get pods -l k8s-app=cilium

# Revisar logs de un pod específico de Cilium
kubectl -n kube-system logs <nombre-del-pod-cilium>

```

---

## 8. 🛠 Mantenimiento y operaciones comunes

Estos comandos te serán útiles para el mantenimiento diario:

```bash
# Actualizar Cilium (generar nuevo manifiesto con la nueva versión)
helm template cilium cilium/cilium --version <nueva-versión> ... > cilium-new.yaml
kubectl apply -f cilium-new.yaml

# Reiniciar todos los pods de Cilium
kubectl -n kube-system delete pods -l k8s-app=cilium

# Ver estado y métricas de Cilium
cilium status
```

Para más información, consulta la [documentación oficial de Cilium](https://docs.cilium.io/) y la [documentación de Gateway API](https://gateway-api.sigs.k8s.io/).
