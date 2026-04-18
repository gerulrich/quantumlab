# Renovate

Renovate es la herramienta que automatiza actualizaciones de dependencias en este repositorio. En QuantumLab se ejecuta como un CronJob de Kubernetes y abre PRs en GitHub según la configuración declarada en Git.

## Organización de archivos

La configuración de Renovate se organiza en tres niveles:

- `renovate.json` (raíz del proyecto): reglas globales de Renovate (por ejemplo, `kubernetes.fileMatch`).
- `infrastructure/base/controllers/renovate/`:
  - `namespace.yaml`: namespace `renovate`.
  - `configmap.yaml`: configuración no sensible (`RENOVATE_PLATFORM`, `RENOVATE_BASE_BRANCHES`, etc.).
  - `cronjob.yaml`: ejecución periódica del contenedor `renovate/renovate`.
- `infrastructure/base/secrets/`:
  - `renovate.yaml`: secretos (`RENOVATE_TOKEN`, `RENOVATE_GIT_PRIVATE_KEY`) cifrados con SOPS.

## Configuración actual

### Ejecución en Kubernetes

El CronJob (`infrastructure/base/controllers/renovate/cronjob.yaml`) ejecuta Renovate con este flujo:

- Schedule: `@hourly`.
- Imagen: `renovate/renovate:latest`.
- Repositorio objetivo actual (argumento): `gerulrich/quantumlab`.
- Carga de variables por `envFrom` desde:
  - Secret `renovate-secrets`.
  - ConfigMap `renovate-configmap`.

### Variables de configuración (ConfigMap)

En `infrastructure/base/controllers/renovate/configmap.yaml` se definen parámetros operativos:

- `RENOVATE_AUTODISCOVER=false`: no escanea automáticamente todos los repositorios.
- `RENOVATE_PLATFORM=github`: backend de integración.
- `RENOVATE_BASE_BRANCHES=master`: rama base para PRs.
- `RENOVATE_GIT_AUTHOR=Renovate[bot] <${ADMIN_EMAIL}>`: autor de commits.
- `RENOVATE_GIT_COMMIT_SIGNING=true`: firma de commits habilitada.

### Reglas de Renovate (renovate.json)

El archivo `renovate.json` contiene reglas de matching para manifiestos Kubernetes:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "kubernetes": {
    "fileMatch": [
      "\\.yaml$"
    ]
  }
}
```

## Secretos

Los secretos de Renovate están en `infrastructure/base/secrets/renovate.yaml` y se gestionan con SOPS.

Variables sensibles actuales:

- `RENOVATE_TOKEN`: token de GitHub para lectura/escritura de PRs.
- `RENOVATE_GIT_PRIVATE_KEY`: clave privada para firma/autenticación Git.

Recomendaciones:

1. Nunca commitear estos valores en texto plano.
2. Mantener el archivo cifrado con SOPS (`ENC[...]`).
3. Si se rota token o clave, actualizar el secreto y reconciliar Flux.

## Ejemplos de cambios comunes

### Agregar un nuevo repositorio para escaneo

Actualmente el CronJob usa un único argumento (`gerulrich/quantumlab`). Para añadir más repositorios, agrega más argumentos en `infrastructure/base/controllers/renovate/cronjob.yaml`:

```yaml
args:
  - gerulrich/quantumlab
  - gerulrich/otro-repo
  - gerulrich/infra-shared
```

### Cambiar frecuencia de ejecución

En `infrastructure/base/controllers/renovate/cronjob.yaml`, modifica `spec.schedule`.

Ejemplo (cada 6 horas):

```yaml
spec:
  schedule: "0 */6 * * *"
```

### Cambiar rama base de PRs

En `infrastructure/base/controllers/renovate/configmap.yaml`:

```yaml
data:
  RENOVATE_BASE_BRANCHES: "main"
```

## Operación básica

Después de cambios en manifiestos o secretos, aplicar flujo GitOps normal (commit/push) y verificar en el clúster:

```bash
kubectl get cronjob -n renovate
kubectl get jobs -n renovate
kubectl logs -n renovate job/<nombre-job>
```

## Referencias

- [Renovate Docs](https://docs.renovatebot.com/)
- [Renovate Configuration Options](https://docs.renovatebot.com/configuration-options/)
- [Cron Syntax](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
