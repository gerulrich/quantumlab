# SOPS

SOPS es una herramienta para gestionar secretos cifrados en archivos YAML y JSON. En este repositorio se utiliza junto con Age para versionar secretos de Kubernetes en Git sin exponer información sensible, permitiendo que Flux los descifre de forma segura en el clúster.

## Crear una nueva clave Age

Para generar un nuevo par de claves Age:

```bash
age-keygen -o age.key

# Mostrar la clave pública para actualizar .sops.yaml
cat age.key | grep "public key"
```

Luego, actualiza `.sops.yaml` con la nueva clave pública:

```yaml
---
creation_rules:
  - path_regex: infrastructure/.*/secrets/.*\.yaml$
    encrypted_regex: "^(data|stringData)$"
    age: >-
      <tu_nueva_clave_publica_aquí>
```

Para recifrar secretos con la nueva clave, vuelve a aplicar cifrado sobre cada archivo:

```bash
source scripts/quantum-env.sh
sops --encrypt --in-place <path>/mi-secreto.yaml
```

## Operaciones comunes

```bash
source scripts/quantum-env.sh

# Ver un secreto descifrado sin modificar el archivo
sops --decrypt infrastructure/base/secrets/mi-secreto.yaml

# Editar un secreto (se cifrará automáticamente al guardar)
sops infrastructure/base/secrets/mi-secreto.yaml

# Cifrar un archivo manualmente
sops --encrypt --in-place ruta/al/secreto.yaml
```

## Configuración del repositorio

El archivo `.sops.yaml` en la raíz del repositorio define las reglas de cifrado:

```yaml
# Contenido simplificado del archivo .sops.yaml
creation_rules:
  - path_regex: infrastructure/.*/secrets/.*\.yaml$
    encrypted_regex: "^(data|stringData)$"
    age: >-
      age1fjw3xzg4xdtqhww82knn78zwwrye3larq42qrdvnrvztcnpf94hsv899fc
```

Esta regla aplica cifrado a secretos bajo `infrastructure/.*/secrets/.*\.yaml`, afectando solo `data` y `stringData`.

## Integración con Flux

Flux descifra secretos en el clúster mediante la configuración `decryption` en las Kustomizations.

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

## Referencias

- [Documentación de SOPS](https://github.com/mozilla/sops)
- [Documentación de Age](https://github.com/FiloSottile/age)
