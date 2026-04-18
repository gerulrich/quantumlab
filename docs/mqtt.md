# Mosquitto (MQTT)

Eclipse Mosquitto es un broker de mensajes MQTT ligero, eficiente y ampliamente utilizado en entornos IoT. Está diseñado para gestionar comunicación publish/subscribe entre sensores, automatizaciones, dispositivos embebidos y otros clientes MQTT con una configuración simple y flexible.

## Configuración del broker

La configuración principal está en `apps/base/mosquitto/configmap.yaml`. Ese ConfigMap define los archivos de configuración que Mosquitto consume dentro del contenedor, principalmente `mosquitto.conf` y `aclfile`.

Parámetros actuales relevantes:

- `persistence false`: no conserva mensajes ni estado entre reinicios.
- `log_dest stdout`: logs enviados a stdout para inspección desde Kubernetes.
- `allow_anonymous false`: no acepta conexiones sin credenciales.
- `password_file /mosquitto/config/passwordfile`: archivo de credenciales nativo de Mosquitto, montado desde el Secret.
- `listener 1883`: puerto MQTT expuesto por el broker.
- `#acl_file /mosquitto/config/aclfile`: el archivo ACL está montado, pero hoy la directiva está comentada.

En la práctica, este ConfigMap reemplaza los archivos de configuración tradicionales de Mosquitto. Cualquier cambio de comportamiento del broker, como autenticación, logging, persistencia o uso de ACLs, se define ahí.

## ACL y usuarios

El `aclfile` también se define dentro del mismo ConfigMap y se monta como archivo de configuración adicional de Mosquitto.

Estado actual:

- Existe una regla para el usuario `mqtt_z2m`.
- Esa regla permite `topic readwrite #`, es decir, acceso total a todos los topics.

Si se quiere endurecer el acceso, este es el archivo donde deben definirse permisos por usuario o por jerarquía de topics.

Ejemplo para restringir un usuario a una rama concreta:

```text
user mqtt_sensor
topic read sensors/+/state
topic write sensors/+/set
```

Si se va a aplicar ACL de forma efectiva, además de editar `aclfile`, hay que habilitar `acl_file /mosquitto/config/aclfile` en `mosquitto.conf`.

## Credenciales

Las credenciales del broker están en `apps/base/mosquitto/secrets.yaml` bajo la clave `passwordfile`.

Ese archivo representa el formato nativo que espera Mosquitto: una línea por usuario con su contraseña hasheada.

Ejemplo de contenido lógico del `passwordfile`:

```text
usuario1:$7$101$...
usuario2:$7$101$...
```

Para agregar un usuario nuevo:

1. Genera o actualiza la entrada correspondiente en formato Mosquitto.
2. Sustituye el contenido de `passwordfile` en `apps/base/mosquitto/secrets.yaml`.
3. Cifra el archivo nuevamente con SOPS.

Para más detalles sobre cómo cifrar o actualizar este secreto, consulta [docs/sops.md](/Users/germanulrich/git/gerulrich/quantumlab/docs/sops.md).

## Cambios comunes

### Agregar un nuevo usuario MQTT

Actualiza `apps/base/mosquitto/secrets.yaml` con una nueva entrada dentro de `passwordfile`.

### Restringir permisos por topics

Edita `aclfile` en `apps/base/mosquitto/configmap.yaml` y habilita la directiva `acl_file` en `mosquitto.conf`.

## Operación básica

Comandos útiles para verificar el estado del broker:

```bash
kubectl logs deploy/mosquitto -n iot
kubectl get secret mosquitto-credentials -n iot
kubectl get configmap mosquitto-config -n iot -o yaml
```

## Referencias

- [Mosquitto Documentation](https://mosquitto.org/documentation/)
- [ACL File Format](https://mosquitto.org/man/mosquitto-conf-5.html)
