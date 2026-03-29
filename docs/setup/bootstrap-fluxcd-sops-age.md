# Flux CD con SOPS y Age

Esta guía explica cómo inicializar y trabajar con Flux CD y SOPS.

---

## 📦 Requisitos previos

Antes de comenzar, asegúrate de tener instalado:

- [`flux`](https://github.com/fluxcd/flux2/releases) - CLI para interactuar con Flux CD
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/) - Cliente de Kubernetes
- [`age`](https://github.com/FiloSottile/age) - Herramienta de cifrado
- [`sops`](https://github.com/mozilla/sops) - Editor de secretos cifrados
- Token de GitHub con permisos para el repositorio

---

## Estructura del repositorio

El repositorio está organizado de la siguiente manera:

```
quantumlab/
├── apps/                       # Aplicaciones a desplegar
│   ├── base/                   # Configuraciones base (mosquitto, nginx)
│   └── quantum-talos/          # Overlays específicos del clúster
├── clusters/                   # Configuraciones específicas por clúster
│   ├── quantum-oci/            # Clúster en Oracle Cloud Infrastructure
│   └── quantum-talos/          # Clúster Talos Linux (flux-system, apps.yaml, helm.yaml, infra.yaml)
├── config/                     # Configuraciones de sistema (cilium, podman, talos)
├── docs/                       # Documentación
├── helm/                       # Releases de Helm (cert-manager)
├── infrastructure/             # Recursos de infraestructura
│   ├── base/                   # Recursos base (configs, controllers, secrets)
│   └── quantum-talos/          # Overlays específicos del clúster
├── scripts/                    # Scripts de utilidad (quantum-env.sh, vm-create-qemu.sh)
├── .sops.yaml                  # Configuración de cifrado SOPS
└── renovate.json               # Configuración de Renovate Bot
```

En los archivos [`clusters/quantum-talos/apps.yaml`](../../clusters/quantum-talos/apps.yaml), [`clusters/quantum-talos/helm.yaml`](../../clusters/quantum-talos/helm.yaml) y [`clusters/quantum-talos/infra.yaml`](../../clusters/quantum-talos/infra.yaml) se definen las kustomizaciones que apuntan a los directorios [`apps/quantum-talos`](../../apps/quantum-talos), [`helm`](../../helm) e [`infrastructure/quantum-talos`](../../infrastructure/quantum-talos), respectivamente. Estos archivos especifican la configuración de los recursos que Flux desplegará en el clúster de Kubernetes.

---

# 1️⃣ Inicialización de Flux en un nuevo clúster

## 1.1 Exportar token de GitHub

Configura tu token de acceso personal de GitHub:

```bash
export GITHUB_TOKEN=<tu-token-de-github>
```

> **Importante**: El token debe tener permisos de `repo` para poder crear webhooks y acceder al repositorio.

## 1.2 Bootstrap de Flux con el repositorio

Ejecuta el bootstrap de Flux para conectar tu clúster con este repositorio:

```bash
flux bootstrap github \
  --token-auth \
  --owner=gerulrich \
  --repository=quantumlab \
  --branch=master \
  --path=clusters/quantum-talos \
  --personal
```

> Este comando instala los componentes de Flux en tu clúster y configura la sincronización con este repositorio.

## 1.3 Configurar la clave Age en el clúster

Para que Flux pueda descifrar los secretos, necesitas agregar la clave Age privada al clúster:

```bash
# Crear secreto sops-age para que flux sea capaz de desencriptar los secretos
kubectl create secret generic sops-age \
  --namespace=flux-system \
  --from-file=age.agekey=./age.key
```

> **Seguridad**: La clave privada Age no está incluida en el repositorio por razones de seguridad.

# Agregar configuracion
````bash
kubectl apply -f config/quantum-talos/cluster-config.yaml
````

# Reconciliar cluster
```bash
flux reconcile kustomization infra
```


## 1.4 Validar la instalación de Flux

Verifica que Flux se ha instalado correctamente:

```bash
# Ver todos los recursos de Flux
flux get all

# Verificar el estado de las Kustomizations
flux get kustomizations

# Comprobar que los controladores de Flux están en ejecución
kubectl -n flux-system get pods
```



## 1.5 Verificar el descifrado de secretos

Comprueba que los secretos se están descifrando correctamente:

```bash
# Ver logs del controlador de Kustomize para verificar el descifrado
flux logs --kind=kustomization --name=infra

# Verificar que los secretos existen en sus respectivos namespaces
# Por ejemplo, para verificar un secreto específico:
kubectl get secret nombre-del-secreto -n namespace-target
```

---

## 📖 Información adicional

Para operaciones avanzadas y mantenimiento de Flux + SOPS, consulta:

- [Flux CD y SOPS - Información adicional y operaciones](../fluxcd-sops-operations.md)