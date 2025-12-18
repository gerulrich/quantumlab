# ⚛️ QuantumLab

![Estado](https://img.shields.io/badge/Estado-En%20Desarrollo-yellow)
![Licencia](https://img.shields.io/badge/Licencia-MIT-blue)
![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.34.2-326CE5?logo=kubernetes&logoColor=white)
![Talos](https://img.shields.io/badge/Talos-v1.11.6-lightgrey?logo=linux&logoColor=white)
![FluxCD](https://img.shields.io/badge/FluxCD-v2.7.5-4353ff?logo=flux&logoColor=white)

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

## 🧰 Servicios del Homelab

| Categoría         | Servicio            | Estado         | Plataforma actual    | Descripción breve                        |
|------------------|---------------------|----------------|----------------------|------------------------------------------|
| Domótica          | 🏠 Home Assistant    | ✅ En uso       | Podman               | Gestión de dispositivos IoT              |
|                   | 🔄 Node-RED          | ✅ En uso       | Podman               | Automatización basada en flujos          |
|                   | 📡 MQTT              | 🔧 En progreso  | Podman  | Broker de mensajería IoT — [docs/mqtt.md](docs/mqtt.md) |
|                   | 🔌 ESPHome           | ✅ En uso       | Podman               | Firmware para dispositivos IoT           |
|                   | 🧿 Zigbee2MQTT       | ✅ En uso       | Podman               | Puente Zigbee a MQTT                     |
| Media             | 🎬 Plex              | ✅ En uso       | Podman               | Servidor de medios                       |
|                   | 📸 PhotoPrism        | ✅ En uso       | Podman               | Galería de fotos privada                 |
|                   | 📤 Transmission      | ✅ En uso       | Podman               | Cliente torrent                          |
| Infraestructura   | 🔐 Vaultwarden       | ✅ En uso       | Podman               | Gestor de contraseñas                    |
|                   | 🌐 NGINX             | ✅ En uso       | Podman               | Reverse proxy                            |
|                   | 🕳️ Pi-hole           | ✅ En uso       | Podman               | DNS y bloqueo de anuncios                |
|                   | ☁️ Cloudflared       | ✅ En uso       | Podman               | Tunnel seguro (Cloudflare)               |
|                   | 🧑‍💻 Guacamole         | ✅ En uso       | Podman               | Escritorio remoto vía web                |
|                   | 🍃 MongoDB           | ✅ En uso       | Podman               | Base de datos NoSQL                      |
|                   | 🧪 Mongo-UI          | ✅ En uso       | Podman               | Interfaz web para MongoDB                |
|                   | 🔍 MQTT Explorer     | ✅ En uso       | Podman               | Interfaz visual para MQTT                |
| Plataforma        | 🐧 Talos Linux       | ⚙️ Configurando | N/A                  | OS minimalista para Kubernetes           |
| Orquestador       | ☸️ Kubernetes        | ⚙️ Configurando | Talos                | Cluster principal                        |
| GitOps            | 🔄 FluxCD            | ⚙️ Configurando | Kubernetes           | Infraestructura como código              |
| Seguridad         | 🧾 SOPS              | ⚙️ Configurando | Kubernetes           | Gestión segura de secretos               |
| Red               | 🌐 Cilium            | ⚙️ Configurando | Kubernetes           | CNI avanzado con observabilidad          |
| VPN / Mesh        | 🧠 Tailscale         | ⚙️ Configurando | Kubernetes           | Red privada entre dispositivos           |
| Paquetes          | 🎯 Helm              | ⚙️ Configurando | Kubernetes           | Gestión de charts                        |
| A implementar     | 🗣️ Piper             | 🕐 Pendiente    | Por definir          | TTS de código abierto                    |
|                   | 🧠 Faster-Whisper    | 🕐 Pendiente    | Por definir          | STT optimizado                           |
|                   | 🤖 Ollama            | 🕐 Pendiente    | Por definir          | LLMs locales (como llama.cpp)            |

## 🚀 Instalación

1. [Instalación del clúster Talos](docs/talos-bootstrap.md)
2. [Configuración de Cilium y API Gateway](docs/cilium-api-gateway.md)
3. [Flux CD con SOPS y Age](docs/bootstrap-fluxcd-sops-age.md)
4. [Cert-Manager y Gateway con TLS](docs/cert-manager-routes.md)

### 📖 Documentación adicional

- [Compartición de IP en Load Balancers de Cilium](docs/cilium-lb-ipam-sharing.md)
- [MQTT con Mosquitto](docs/mqtt.md)
- [Renovate para actualizaciones automáticas](docs/renovate.md)

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