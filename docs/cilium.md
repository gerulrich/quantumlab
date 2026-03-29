# Cilium

## Compartición de IP en Load Balancers

## 🔗 Anotación `io.cilium/lb-ipam-sharing-key`

La anotación `io.cilium/lb-ipam-sharing-key` permite que múltiples servicios de tipo LoadBalancer compartan la misma dirección IP externa cuando tienen el mismo valor de clave de compartición.

## 📋 Sintaxis

```yaml
metadata:
  annotations:
    "io.cilium/lb-ipam-sharing-key": "<clave-de-comparticion>"
```

## 🎯 Casos de uso

### 1. Gateways HTTP/HTTPS

El caso más común es compartir IP entre gateways HTTP y HTTPS:

```yaml
# Gateway HTTP (puerto 80)
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: http-gateway
  namespace: gateway
spec:
  gatewayClassName: cilium
  infrastructure:
    annotations:
      "io.cilium/lb-ipam-sharing-key": "web-traffic"
  listeners:
  - name: http-listener
    protocol: HTTP
    port: 80

---
# Gateway HTTPS (puerto 443)
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: tls-gateway
  namespace: gateway
spec:
  gatewayClassName: cilium
  infrastructure:
    annotations:
      "io.cilium/lb-ipam-sharing-key": "web-traffic"  # Misma clave
  listeners:
  - name: https-listener
    protocol: HTTPS
    port: 443
```

### 2. Servicios de aplicación relacionados

```yaml
# Servicio API
apiVersion: v1
kind: Service
metadata:
  name: api-service
  annotations:
    "io.cilium/lb-ipam-sharing-key": "app-cluster"
spec:
  type: LoadBalancer
  ports:
  - port: 8080
    targetPort: 8080

---
# Servicio de métricas
apiVersion: v1
kind: Service
metadata:
  name: metrics-service
  annotations:
    "io.cilium/lb-ipam-sharing-key": "app-cluster"  # Misma clave
spec:
  type: LoadBalancer
  ports:
  - port: 9090
    targetPort: 9090
```

## ⚠️ Consideraciones importantes

### Requisitos obligatorios

1. **Puertos únicos**: Los servicios que comparten IP deben usar puertos diferentes
2. **Mismo pool de IPs**: Deben estar en el mismo rango de IPs del pool de Cilium
3. **Clave idéntica**: El valor de `lb-ipam-sharing-key` debe ser exactamente igual

### Limitaciones

- No se puede compartir el mismo puerto entre servicios con la misma clave
- La clave de compartición es sensible a mayúsculas y minúsculas
- Solo funciona con servicios de tipo `LoadBalancer`

## 🔍 Comandos de verificación

```bash
# Ver todos los servicios LoadBalancer y sus IPs
kubectl get svc -A --field-selector spec.type=LoadBalancer -o wide

# Verificar Gateways y sus IPs asignadas
kubectl get gateway -A -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,IP:.status.addresses[0].value

# Buscar servicios con la misma clave de compartición
kubectl get svc -A -o yaml | grep -B10 -A2 "lb-ipam-sharing-key"

# Ver anotaciones específicas de un Gateway
kubectl get gateway <nombre-gateway> -n <namespace> -o jsonpath='{.spec.infrastructure.annotations}'
```

## 🌟 Beneficios

1. **Optimización de IPs**: Reduce el número de direcciones IP externas necesarias
2. **Gestión simplificada**: Una sola IP para múltiples servicios relacionados
3. **Ahorro de costos**: Especialmente útil en proveedores cloud que cobran por IP pública
4. **Organización lógica**: Agrupa servicios relacionados bajo la misma dirección

## 📚 Referencias

- [Documentación oficial de Cilium Load Balancing](https://docs.cilium.io/en/stable/network/lb-ipam/)
- [Gateway API](https://gateway-api.sigs.k8s.io/)
- [Cilium Service Load Balancing](https://docs.cilium.io/en/stable/network/servicemesh/load-balancing/)