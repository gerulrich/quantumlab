# Mosquitto (MQTT) — Manifiestos

Directorio con los manifiestos:

`apps/base/mosquitto/`

Explicación de los manifiestos

1) Se crea el namespace

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: mqtt
```

2) ConfigMap con la configuración del broker

Contiene la configuración principal (por ejemplo `mosquitto.conf`) y, opcionalmente, un archivo de ACL. Este ConfigMap se monta en el pod para que el broker use la configuración declarada.

```yaml
apiVersion: v1
kind: ConfigMap
data:
  mosquitto.conf: |
    # Minimal mosquitto configuration
    persistence true
    persistence_location /mosquitto/data/
    allow_anonymous false
    password_file /mosquitto/config/passwordfile
    listener 1883 0.0.0.0
  aclfile: |
    # example ACL: allow all (replace with proper rules)
    user anonymous
    topic readwrite # placeholder
```

3) Secret con credenciales

Contiene las credenciales (passwordfile u otros secretos). En este repositorio los secretos están cifrados con SOPS + Age: aparecerán como `ENC[...]` en el YAML. Flux los desencripta antes de aplicar.

```yaml
apiVersion: v1
kind: Secret
type: Opaque
stringData:
  passwordfile: ENC[...]  # valor cifrado por SOPS
```

  Ejemplo (sin cifrar) — cómo sería el Secret con el passwordfile en claro:

  ```yaml
  apiVersion: v1
  kind: Secret
  type: Opaque
  stringData:
  passwordfile: |
    # username:hashed_password (usando `mosquitto_passwd -b -H sha512`)
    # ejemplo generado: alice:$6$...hashed...
    user1:password1
    user2:password2
  ```

  Los secretos deben ser cifrados con `sops` antes de commitearlos, puedes hacerlo así:

  ```bash
  # cifrar in-place
  sops --encrypt --in-place apps/base/mosquitto/secrets.yaml
  ```

4) Deployment del broker

Define el contenedor `eclipse-mosquitto`, volúmenes y `volumeMounts` (monta el ConfigMap y el Secret para la configuración y las credenciales).

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
        - name: mosquitto
          image: eclipse-mosquitto:2.x
          volumeMounts:
            - name: config-volume
              mountPath: /mosquitto/config/mosquitto.conf
              subPath: mosquitto.conf
            - name: credentials-volume
              mountPath: /mosquitto/config/passwordfile
              subPath: passwordfile
      volumes:
        - name: config-volume
          configMap:
            name: mosquitto-config
        - name: acl-volume
          configMap:
            name: mosquitto-config
            items:
              - key: aclfile
                path: aclfile
        - name: credentials-volume
          secret:
            secretName: mosquitto-credentials
        - name: data-volume
          emptyDir: {}
```

5) Service para exponer el puerto MQTT

Expone el puerto 1883 para que clientes MQTT puedan conectarse. En este repositorio el `Service` se define con `type: LoadBalancer` y añade la etiqueta `color: blue` en `metadata.labels`. Esa etiqueta se usa por Cilium para seleccionar la IP desde el IPPool `blue-pool` cuando se solicita una IP de tipo LoadBalancer.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mosquitto
  namespace: mqtt
  labels:
    color: blue   # pide IP del pool 'blue-pool' en Cilium
spec:
  selector:
    app: mosquitto
  ports:
    - protocol: TCP
      port: 1883
      targetPort: 1883
  type: LoadBalancer
```
