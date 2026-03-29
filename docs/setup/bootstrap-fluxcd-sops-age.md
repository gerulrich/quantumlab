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

# 2️⃣ Información adicional y operaciones

## 2.1 Crear una nueva clave Age

Si necesitas generar una nueva clave Age:

```bash
# Generar un nuevo par de claves
age-keygen -o new-age.key

# Mostrar la clave pública (para actualizar .sops.yaml)
cat new-age.key | grep "public key"
```

> Si generas una nueva clave, deberás actualizar el archivo `.sops.yaml` y volver a cifrar todos los secretos existentes.

## 2.2 Cifrado y descifrado manual con SOPS

Para trabajar con secretos cifrados localmente:

```bash
# Configurar variable de entorno para SOPS (usando el script del repo)
. ./scripts/quantum-env.sh

# Ver un secreto descifrado sin modificar el archivo
sops --decrypt infrastructure/base/secrets/mi-secreto.yaml

# Editar un secreto (se cifrará automáticamente al guardar)
sops infrastructure/base/secrets/mi-secreto.yaml

# Cifrar un archivo manualmente
sops --encrypt --in-place ruta/al/secreto.yaml
```

## 2.3 Configuración de SOPS en el repositorio

El archivo `.sops.yaml` en la raíz del repositorio define las reglas de cifrado:

```yaml
# Contenido simplificado del archivo .sops.yaml
creation_rules:
  - path_regex: infrastructure/.*/secrets/.*\.yaml$
    encrypted_regex: "^(data|stringData)$"
    age: >-
      age1fjw3xzg4xdtqhww82knn78zwwrye3larq42qrdvnrvztcnpf94hsv899fc
```

> **Explicación**: Esta configuración indica que todos los archivos en rutas que coincidan con `infrastructure/.*/secrets/.*\.yaml` serán cifrados, específicamente los campos bajo `data` o `stringData`, usando la clave Age especificada.

---

# 3️⃣ Información complementaria

## 3.1 Kustomization con SOPS

La configuración de Flux para utilizar SOPS se encuentra en los archivos de Kustomization:

```yaml
# Fragmento relevante de clusters/quantum-talos/infra.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: infra
  namespace: flux-system
spec:
  # ...otras configuraciones...
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

> **Nota**: Esta configuración le indica a Flux que debe descifrar secretos usando SOPS con la clave almacenada en el secreto `sops-age`.

---

## 🛠 Comandos útiles

```bash
# Reconciliar manualmente los recursos
flux reconcile kustomization infra

# Ver eventos de recursos específicos
flux events --for=Kustomization/infra

# Suspender la reconciliación automática
flux suspend kustomization infra

# Reanudar la reconciliación automática
flux resume kustomization infra

# Obtener la versión actual de los componentes
flux version
```

---

Para más información, consulta:
- [Documentación oficial de Flux CD](https://fluxcd.io/flux/)
- [Documentación de SOPS](https://github.com/mozilla/sops)
- [Documentación de Age](https://github.com/FiloSottile/age)