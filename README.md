# ⚛️ QuantumLab

![Estado](https://img.shields.io/badge/Estado-En%20Desarrollo-yellow)
![Licencia](https://img.shields.io/badge/Licencia-MIT-blue)
![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.35.3-326CE5?logo=kubernetes&logoColor=white)
![Talos](https://img.shields.io/badge/Talos-v1.12.6-lightgrey?logo=linux&logoColor=white)
![FluxCD](https://img.shields.io/badge/FluxCD-v2.8.3-4353ff?logo=flux&logoColor=white)
[![Cluster Check](https://img.shields.io/github/actions/workflow/status/gerulrich/quantumlab/cluster-status-badge.yml?branch=master&label=cluster%20check&style=flat)](https://github.com/gerulrich/quantumlab/actions/workflows/cluster-status-badge.yml)

**QuantumLab** es un proyecto de infraestructura personal para un homelab basado en Kubernetes.
Diseñado como entorno de pruebas, aprendizaje y portfolio técnico, implementa buenas prácticas de automatización y GitOps.

> Un laboratorio personal donde la infraestructura se gestiona con estándares profesionales y se mantiene 100% como código.

---

## 🎯 Objetivos del Proyecto

- Mantener una infraestructura 100% declarativa y versionada
- Migrar servicios de Podman a Kubernetes siguiendo principios GitOps
- Implementar buenas prácticas de DevOps en un entorno personal
- Servir como entorno de aprendizaje y portfolio técnico

## 🏗️ Arquitectura

QuantumLab utiliza:
- **Talos Linux** como sistema operativo inmutable y seguro
- **Kubernetes** como plataforma de orquestación
- **FluxCD** para gestión declarativa y GitOps
- **Cilium** como CNI para networking avanzado
- **SOPS + Age** para gestión segura de secretos

Actualmente, varias aplicaciones están desplegadas bajo **Podman**, y se migrarán progresivamente a Kubernetes.

## 🚀 Instalación

1. [Configuración inicial del entorno](docs/setup/setup.md)
2. [Instalación del clúster Talos](docs/setup/talos-bootstrap.md)
3. [Configuración de Cilium y API Gateway](docs/setup/cilium-api-gateway.md)
4. [Flux CD con SOPS y Age](docs/setup/bootstrap-fluxcd-sops-age.md)

## 🧰 Servicios del Homelab

### Servicios de plataforma

| Categoría         | Componente          | Descripción breve                        |
|------------------|---------------------|------------------------------------------|
| Plataforma        | 🐧 Talos Linux       | OS minimalista para Kubernetes ([Info adicional](docs/talos.md)) |
| Orquestador       | ☸️ Kubernetes        | Cluster principal                        |
| GitOps            | 🔄 FluxCD            | Infraestructura como código ([Info adicional](docs/fluxcd.md)) |
| Seguridad         | 🧾 SOPS              | Gestión segura de secretos ([Info adicional](docs/sops.md)) |
|                   | 🔒 Cert-Manager      | Gestión automática de certificados TLS ([Info adicional](docs/cert-manager.md)) |
| Red               | 🌐 Cilium            | CNI avanzado con observabilidad ([Info adicional](docs/cilium.md)) |
|                   | ☁️ Cloudflared       | Tunnel seguro hacia Cloudflare           |
| VPN / Mesh        | 🧠 Tailscale         | Red privada entre dispositivos           |
| Paquetes          | 🎯 Helm              | Gestión de charts                        |

### Servicios de aplicaciones

| Categoría         | Servicio            | Documentación   | Exposición           | Descripción breve                        |
|------------------|---------------------|-----------------|----------------------|------------------------------------------|
| Infraestructura   | 🌐 NGINX             | Pendiente       | Servicio HTTP interno| Reverse proxy                            |
|                   | 🥾 Netboot.xyz       | [Netboot.xyz](docs/netbootxyz.md) | `netboot.lan.${DOMAIN}` + LB | Boot PXE/iPXE y utilidades de rescate    |
|                   | 🔐 OAuth2 Proxy      | Pendiente       | Gateway API          | Proxy de autenticación                   |
|                   | 🪪 Pocket ID         | Pendiente       | Gateway API          | Gestión de identidad                     |
| Domótica          | 📡 Mosquitto         | [MQTT](docs/mqtt.md) | LoadBalancer 1883/TCP | Broker de mensajería IoT              |
| Utilidades        | 🧪 Whoami            | Pendiente       | Gateway API          | Servicio de prueba para rutas HTTP       |
|                   | 🤖 Renovate          | [Renovate](docs/renovate.md) | N/A                  | Actualizaciones automáticas de dependencias |

### Servicios en Podman

| Categoría         | Servicio            | Estado         | Plataforma actual    | Descripción breve                        |
|------------------|---------------------|----------------|----------------------|------------------------------------------|
| Domótica          | 🏠 Home Assistant    | ✅ En uso       | Podman               | Gestión de dispositivos IoT              |
|                   | 🔄 Node-RED          | ✅ En uso       | Podman               | Automatización basada en flujos          |
|                   | 📡 MQTT              | 🔧 En progreso  | Podman               | Broker de mensajería IoT                 |
|                   | 🔌 ESPHome           | ✅ En uso       | Podman               | Firmware para dispositivos IoT           |
|                   | 🧿 Zigbee2MQTT       | ✅ En uso       | Podman               | Puente Zigbee a MQTT                     |
| Media             | 🎬 Plex              | ✅ En uso       | Podman               | Servidor de medios                       |
|                   | 📸 PhotoPrism        | ✅ En uso       | Podman               | Galería de fotos privada                 |
|                   | 📤 Transmission      | ✅ En uso       | Podman               | Cliente torrent                          |
| Infraestructura   | 🔐 Vaultwarden       | ✅ En uso       | Podman               | Gestor de contraseñas                    |
|                   | 🌐 NGINX             | ✅ En uso       | Podman               | Reverse proxy                            |
|                   | 🕳️ Pi-hole           | ✅ En uso       | Podman               | DNS y bloqueo de anuncios                |
|                   | 🧑‍💻 Guacamole         | ✅ En uso       | Podman               | Escritorio remoto vía web                |
|                   | 🍃 MongoDB           | ✅ En uso       | Podman               | Base de datos NoSQL                      |
|                   | 🧪 Mongo-UI          | ✅ En uso       | Podman               | Interfaz web para MongoDB                |
|                   | 🔍 MQTT Explorer     | ✅ En uso       | Podman               | Interfaz visual para MQTT                |
| A implementar     | 🗣️ Piper             | 🕐 Pendiente    | Por definir          | TTS de código abierto                    |
|                   | 🧠 Faster-Whisper    | 🕐 Pendiente    | Por definir          | STT optimizado                           |
|                   | 🤖 Ollama            | 🕐 Pendiente    | Por definir          | LLMs locales (como llama.cpp)            |

## 📂 Estructura del Repositorio

```
quantumlab/
├── apps/                  # Aplicaciones desplegadas en Kubernetes
├── clusters/              # Configuración de clusters (FluxCD)
├── config/                # Configuraciones (Talos, Cilium, Podman)
├── docs/                  # Documentación técnica
├── helm/                  # Charts de Helm
├── infrastructure/        # Recursos de infraestructura K8s
└── scripts/               # Scripts de utilidad
```

## 📄 Licencia

MIT — Libre para estudiar, adaptar y reutilizar.

---

*Si este proyecto te resulta útil o inspirador, ¡una estrella es siempre bienvenida! ⭐*