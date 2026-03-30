# SOPS

Esta guía reúne operaciones de mantenimiento y uso avanzado de SOPS y Age en el repositorio.

---

## 1️⃣ Crear una nueva clave Age

Si necesitas generar una nueva clave Age:

```bash
# Generar un nuevo par de claves
age-keygen -o new-age.key

# Mostrar la clave pública (para actualizar .sops.yaml)
cat new-age.key | grep "public key"
```

> Si generas una nueva clave, deberás actualizar el archivo `.sops.yaml` y volver a cifrar todos los secretos existentes.

## 2️⃣ Cifrado y descifrado manual con SOPS

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

## 3️⃣ Configuración de SOPS en el repositorio

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

## 4️⃣ Kustomization con SOPS

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

Para más información, consulta:
- [Documentación de SOPS](https://github.com/mozilla/sops)
- [Documentación de Age](https://github.com/FiloSottile/age)
