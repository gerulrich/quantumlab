# Netboot.xyz en Kubernetes

## Resumen

Netboot.xyz está desplegado en Kubernetes como servicio de arranque por red y utilidades de rescate.
La app corre en el namespace `netbootxyz` y expone tanto la UI web como el servicio TFTP.

## Recursos desplegados

- `Deployment` con la imagen `linuxserver/netbootxyz:0.7.6`
- `Service` tipo `LoadBalancer`
- `HTTPRoute` para la UI web
- `PersistentVolume` y `PersistentVolumeClaim` para `config` y `assets`

## Exposición

- UI web: `http://netboot.lan.${DOMAIN}` y `https://netboot.lan.${DOMAIN}`
- Puerto web interno: `3000/TCP`
- Puerto HTTP del contenedor: `9999/TCP` hacia `80/TCP`
- TFTP: `69/UDP`

## Persistencia

Se usan volúmenes NFS para mantener configuración y assets:

- `${NFS_PATH}/netboot/config`
- `${NFS_PATH}/netboot/assets`

## Configuración en OpenWrt

Para que los equipos arranquen por red, OpenWrt debe seguir entregando DHCP y anunciar a netboot.xyz como servidor de arranque.
El punto importante es que el `next-server` debe apuntar a la IP externa del `Service` `LoadBalancer` de netbootxyz, no al hostname web.

### Datos necesarios

- IP del `LoadBalancer` de netbootxyz
- Red o VLAN donde OpenWrt entrega DHCP
- Tipo de clientes que vas a bootear: BIOS, UEFI x86_64 o ambos

### Ejemplo con dnsmasq

En OpenWrt, esto normalmente se configura en `/etc/config/dhcp` mediante opciones adicionales de `dnsmasq`.
Un ejemplo típico sería:

```conf
config dnsmasq
	option enable_tftp '0'
	list dhcp_boot 'netboot.xyz.kpxe'
	list dhcp_option '66,<IP_DEL_LOADBALANCER>'
	list dhcp_match 'set:bios,option:client-arch,0'
	list dhcp_boot 'tag:bios,netboot.xyz.kpxe,,<IP_DEL_LOADBALANCER>'
	list dhcp_match 'set:efi64,option:client-arch,7'
	list dhcp_boot 'tag:efi64,netboot.xyz.efi,,<IP_DEL_LOADBALANCER>'
	list dhcp_match 'set:efi64,option:client-arch,9'
	list dhcp_boot 'tag:efi64,netboot.xyz.efi,,<IP_DEL_LOADBALANCER>'
```

### Qué hace cada opción

- `66`: indica el servidor TFTP o `next-server`
- `netboot.xyz.kpxe`: arranque para clientes BIOS heredados
- `netboot.xyz.efi`: arranque para clientes UEFI x86_64
- `client-arch`: permite distinguir el tipo de firmware del cliente

### Recomendaciones

- Desactiva el TFTP local de OpenWrt si estaba habilitado, para evitar conflicto con `69/UDP`
- Verifica que la IP del `LoadBalancer` sea estable; si cambia, DHCP quedará apuntando al destino incorrecto
- Si usas VLANs, el tráfico entre clientes y la IP del `LoadBalancer` debe estar permitido
- Si algunos equipos no soportan iPXE correctamente, empieza probando solo con UEFI o solo con BIOS para aislar el problema

### Validación rápida

- Confirma que OpenWrt sigue entregando leases DHCP normalmente
- Desde la red cliente, valida que la IP del `LoadBalancer` responda en `69/UDP`
- Inicia un equipo en PXE y revisa si descarga `netboot.xyz.kpxe` o `netboot.xyz.efi`
- Si falla el arranque, revisa primero el tipo de firmware del cliente y luego la IP anunciada por DHCP

## Manifiestos

- `apps/base/netbootxyz`
- `apps/quantum-talos/netbootxyz`
