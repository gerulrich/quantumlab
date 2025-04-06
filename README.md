# ⚛️ QuantumLab

**QuantumLab** es un proyecto de infraestructura personal para un homelab basado en Kubernetes.  
Está diseñado como entorno de pruebas, aprendizaje y portfolio técnico, con foco en buenas prácticas de automatización y GitOps.

Utiliza **Talos Linux** como sistema operativo inmutable, **FluxCD** para gestión declarativa del clúster, y busca mantener toda la infraestructura como código.  
Actualmente, varias aplicaciones están desplegadas bajo **Podman**, y se migrarán progresivamente a Kubernetes.

---

## 🧰 Servicios del Homelab

| Categoría         | Servicio            | Estado         | Plataforma actual    | Descripción breve                        |
|------------------|---------------------|----------------|----------------------|------------------------------------------|
| Domótica          | 🏠 Home Assistant    | ✅ En uso       | Podman               | Gestión de dispositivos IoT              |
|                   | 🔄 Node-RED          | ✅ En uso       | Podman               | Automatización basada en flujos          |
|                   | 📡 MQTT              | ✅ En uso       | Podman               | Broker de mensajería IoT                 |
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
| Plataforma        | 🐧 Talos Linux       | ⚙️ En despliegue | N/A                  | OS minimalista para Kubernetes           |
| Orquestador       | ☸️ Kubernetes        | ⚙️ En despliegue | Talos                | Cluster principal                        |
| GitOps            | 🔄 FluxCD            | ⚙️ Configurando | Kubernetes           | Infraestructura como código              |
| Seguridad         | 🧾 SOPS              | ⚙️ Configurando | Kubernetes           | Gestión segura de secretos               |
| Red               | 🌐 Cilium            | ⚙️ Configurando | Kubernetes           | CNI avanzado con observabilidad          |
| VPN / Mesh        | 🧠 Tailscale         | ⚙️ Configurando | Kubernetes           | Red privada entre dispositivos           |
| Paquetes          | 🎯 Helm              | ✅ En uso       | Kubernetes           | Gestión de charts                        |
| A implementar     | 🗣️ Piper             | 🕐 Pendiente    | Por definir          | TTS de código abierto                    |
|                   | 🧠 Faster-Whisper     | 🕐 Pendiente    | Por definir          | STT optimizado                           |
|                   | 🤖 Ollama            | 🕐 Pendiente    | Por definir          | LLMs locales (como llama.cpp)            |

---

## 📦 Objetivos

- Mantener una infraestructura 100% declarativa y versionada
- Migrar servicios legacy desde Podman a Kubernetes
- Aplicar buenas prácticas de DevOps y GitOps
- Servir como entorno de pruebas, aprendizaje y portfolio técnico

---

## 📁 Estructura del repositorio (en progreso)

- `talos/`: Configuración de Talos para el control plane y los workers
- `flux/`: Configuración de FluxCD y despliegue declarativo de aplicaciones
- `ansible/`: Playbooks de provisión inicial (por ejemplo, preparar nodos físicos)
- `podman/`: Stack de servicios actualmente ejecutándose fuera de Kubernetes
- `docs/`: Documentación técnica y decisiones de diseño
- `scripts/`: Utilidades para automatizar tareas comunes


---

## 🧠 Filosofía del proyecto

QuantumLab aplica un enfoque profesional a un entorno personal:  
infraestructura modular, segura, reproducible y gestionada con prácticas modernas de SRE y GitOps.

---

## 📄 Licencia

MIT — Libre para estudiar, adaptar y reutilizar.  
Si este proyecto te resulta útil o inspirador, ¡una estrella es siempre bienvenida! ⭐

---