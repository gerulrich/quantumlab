# Mini guía: Renovate en este repositorio

Esta guía corta explica cómo está configurado Renovate y cómo trabajar con él en este repositorio.

## ¿Qué es Renovate?
Renovate es una herramienta que automatiza actualizaciones de dependencias y manifiestos en repositorios.

## Dónde está la configuración
- Archivo global de configuración: `renovate.json` (en la raíz del repo).
- CronJob que ejecuta Renovate en Kubernetes: `infrastructure/base/controllers/renovate/cronjob.yaml`.
- ConfigMap con variables por defecto: `infrastructure/base/controllers/renovate/configmap.yaml`.
- Namespace: `infrastructure/base/controllers/renovate/namespace.yaml`.
- Secret con variables de entorno para el contenedor: `infrastructure/base/secrets/renovate.yaml` (nombre: `renovate-container-env`).
- Token de GitHub y otros secretos gestionados por SOPS: `infrastructure/base/secrets/github-token.yaml`.

Si quieres, puedo añadir un breve ejemplo de `renovate.json` con reglas recomendadas o añadir pasos específicos para Flux.
