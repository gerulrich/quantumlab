# Flux CD

Esta guía reúne operaciones avanzadas y tareas de mantenimiento para Flux CD, separadas del flujo principal de setup.

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
