
# OpenTofu

Esta guía resume la configuración de OpenTofu en QuantumLab usando un backend remoto en OCI Object Storage.

---

## ✅ Prerrequisitos

- OCI CLI configurado y autenticado
- Variables locales copiadas desde los ejemplos
- Herramientas del repositorio disponibles en el entorno

---

## 1. Configurar OCI CLI

```bash
source scripts/quantum-env.sh && oci setup config
```

Durante el asistente se solicitarán:
- Ruta del archivo de configuración
- User OCID
- Tenancy OCID
- Región
- Generación de par de claves (la clave pública debe cargarse en la consola de OCI)

---

## 2. Crear bucket y archivos de variables

```bash
source scripts/quantum-env.sh && bash scripts/create-state-bucket.sh
cp config/opentofu/terraform.tfvars.backend.example config/opentofu/terraform.tfvars.backend
cp config/opentofu/terraform.tfvars.example config/opentofu/terraform.tfvars
```

El script muestra en su salida el valor de `s3_endpoint`.

---

## 3. Completar configuración local

En `config/opentofu/terraform.tfvars.backend`:
- Definir `s3_endpoint` con el valor entregado por el script
- Definir credenciales de API key generadas en OCI

En `config/opentofu/terraform.tfvars`:
- Completar el resto de variables del despliegue

---

## 4. Inicializar y aplicar OpenTofu

```bash
source scripts/quantum-env.sh && tofu -chdir=config/opentofu init -backend-config="endpoint=$TF_VAR_s3_endpoint"
source scripts/quantum-env.sh && tofu -chdir=config/opentofu plan
source scripts/quantum-env.sh && tofu -chdir=config/opentofu apply
```

---

## 📚 Referencias

- [Backend remoto detallado](opentofu-backend-setup.md)

