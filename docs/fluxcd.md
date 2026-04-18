# Flux CD

Flux CD es una herramienta de código abierto para la entrega continua (CD) y GitOps diseñada específicamente para Kubernetes. Automatiza el despliegue de aplicaciones al sincronizar el estado deseado de la infraestructura, almacenado en un repositorio Git, con el estado actual del clúster. Se especializa en la reconciliación continua, asegurando que cualquier cambio en Git se aplique automáticamente y que el clúster se mantenga coherente.

## Comandos principales

```bash
# Estado general de todos los recursos gestionados por Flux
flux get all

# Forzar reconciliación completa: re-fetcha el repositorio y aplica todos los cambios
flux reconcile ks flux-system --with-source

# Forzar reconciliación de una kustomization (sin re-fetch del source)
flux reconcile source git flux-system
flux reconcile kustomization <nombre>

# Ver el estado detallado de una kustomization específica
flux get kustomization <nombre> --watch

# Ver eventos de un recurso específico
flux events --for=Kustomization/<nombre>

# Suspender / reanudar la reconciliación automática
flux suspend kustomization <nombre>
flux resume kustomization <nombre>

# Versión de los componentes instalados
flux version
```

## Referencias

- [Documentación oficial de Flux CD](https://fluxcd.io/flux/)
