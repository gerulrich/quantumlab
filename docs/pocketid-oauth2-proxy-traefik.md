# Proteger una aplicación web con Pocket ID, OAuth2 Proxy y Traefik

Esta guía contiene exclusivamente la configuración adicional necesaria para proteger una nueva aplicación web. Pocket ID, OAuth2 Proxy, Traefik y su middleware `oauth2-proxy` ya están configurados en QuantumLab; no crees otro cliente OIDC, secreto, deployment ni middleware.

El acceso documentado es solo desde la LAN. No añadas rutas ni hostnames de Cloudflare para esta aplicación.

## Valores de ejemplo

Para una aplicación desplegada como el Service `app` en el namespace `mi-namespace`, se usará:

| Valor | Ejemplo |
|---|---|
| Hostname LAN | `app.lan.${DOMAIN}` |
| Backend interno | `http://app.mi-namespace.svc.cluster.local:8080` |
| Nombre del router y service de Traefik | `app` |

Sustituye esos valores por los de la aplicación que vayas a publicar.

## 1. Crear el router de Traefik

En [apps/base/oauth/traefik/configmap.yaml](../apps/base/oauth/traefik/configmap.yaml), añade el router y el service siguientes dentro de `data.dynamic.yaml`. El middleware `oauth2-proxy` existente fuerza la autenticación antes de llegar al backend.

```yaml
http:
  routers:
    app:
      rule: "Host(`app.lan.${DOMAIN}`)"
      entryPoints:
        - web
      middlewares:
        - oauth2-proxy
      service: app

  services:
    app:
      loadBalancer:
        servers:
          - url: "http://app.mi-namespace.svc.cluster.local:8080"
```

El backend debe ser el DNS interno de su `Service` de Kubernetes y su puerto HTTP. No expongas el Service de la aplicación con otro `HTTPRoute` que use `app.lan.${DOMAIN}`: Traefik debe ser el único backend del hostname protegido.

## 2. Registrar el hostname en las rutas de Traefik

En [apps/base/oauth/traefik/route.yaml](../apps/base/oauth/traefik/route.yaml), añade `app.lan.${DOMAIN}` a `spec.hostnames` de ambos recursos: `traefik-http-route` y `traefik-tls-route`.

```yaml
hostnames:
  - "app.lan.${DOMAIN}"
```

Ambas rutas deben seguir apuntando al Service `traefik` en el namespace `oauth`.

## 3. Dejar que ExternalDNS publique el registro local

No crees el registro DNS manualmente. ExternalDNS observa los `HTTPRoute`, por lo que al añadir `app.lan.${DOMAIN}` en el paso anterior crea o actualiza el registro en el DNS de la LAN apuntando al Gateway del clúster. No añadas rutas de Cloudflared ni expongas el hostname a Internet.

## 4. Validar

Deja que Flux reconcilie los manifiestos y abre `https://app.lan.${DOMAIN}` desde un equipo conectado a la LAN, en una ventana privada. Debe redirigir al inicio de sesión de Pocket ID y, tras autenticarse, cargar la aplicación.