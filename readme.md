# Trunk Manager API - Servicio para Asterisk/FreePBX

## Descripción

Trunk Manager API es un servicio Node.js que permite la gestión automática de trunks SIP mediante una API REST. Este servicio facilita la creación, configuración y eliminación de trunks sin necesidad de manipular archivos de configuración manualmente.

## Características

- ✅ **Detección automática de proveedores** - Solo necesitas usuario, contraseña y servidor
- ✅ API REST para gestión de trunks
- ✅ Soporte para múltiples proveedores SIP (Twilio, Plivo, SignalWire, Vonage, Telnyx, Custom)
- ✅ Instalación automática como servicio systemd
- ✅ Configuración automática de archivos PJSIP
- ✅ Recarga automática de módulos Asterisk
- ✅ **Sin dependencia de FreePBX** - Funciona independientemente

## Requisitos del Sistema

- Node.js 12.x o superior
- npm (Node Package Manager)
- Asterisk con módulos PJSIP habilitados
- Permisos de escritura en `/etc/asterisk/trunks/`
- Sistema operativo Linux (CentOS 7/Sangoma 7 recomendado)

## 🚀 Instalación

### Instalación Simple (Recomendado)

```bash
# Instalación en 3 comandos
wget https://raw.githubusercontent.com/UnCarnaval/addtrunkapi-module/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

## 📡 Uso de la API

### Health Check
```bash
curl http://tu-servidor:56201/health
```

### Agregar Trunk
```bash
curl -X POST http://tu-servidor:56201/add-trunk \
  -H "Content-Type: application/json" \
  -d '{
    "username": "tu_usuario",
    "password": "tu_password", 
    "server": "sip.telnyx.com"
  }'
```

Respuesta (automático):
```json
{
  "message": "Trunk _ABCDE agregado y recargado correctamente.",
  "trunk": "telnyx_ABCDE",
  "detected_provider": "telnyx",
  "server": "sip.telnyx.com"
}
```

Puedes enviar un nombre específico opcional en el POST:
```bash
curl -X POST http://tu-servidor:56201/add-trunk \
  -H "Content-Type: application/json" \
  -d '{
    "username": "tu_usuario",
    "password": "tu_password", 
    "server": "sip.telnyx.com",
    "trunk": "telnyx_MiTrunkPersonalizado"
  }'
```

Respuesta (manual):
```json
{
  "message": "Trunk MiTrunkPersonalizado agregado y recargado correctamente.",
  "trunk": "telnyx_MiTrunkPersonalizado",
  "detected_provider": "telnyx",
  "server": "sip.telnyx.com"
}
```

### Eliminar Trunk
```bash
curl -X DELETE http://tu-servidor:56201/delete-trunk/telnyx_ABC123
```

Respuesta:
```json
{
  "message": "Trunk telnyx_ABC123 eliminado y configuración recargada."
}
```

### Detectar Proveedor
```bash
curl http://tu-servidor:56201/detect-provider/sip.telnyx.com
```

## 🔧 Comandos Útiles

```bash
# Ver estado del servicio
systemctl status trunkmanager-api

# Ver logs en tiempo real
journalctl -u trunkmanager-api -f

# Reiniciar servicio
systemctl restart trunkmanager-api

# Detener servicio
systemctl stop trunkmanager-api

# Habilitar inicio automático
systemctl enable trunkmanager-api

# Ver trunks existentes
sudo find /etc/asterisk/trunks -maxdepth 1 -type f -name '_*.conf' -print

# Borrar todos los trunks creados por la API
sudo find /etc/asterisk/trunks -maxdepth 1 -type f -name '_*.conf' -delete && sudo asterisk -rx 'pjsip reload'

# Borrar todos los archivos .conf en trunks (incluye archivos manuales)
sudo rm -f /etc/asterisk/trunks/*.conf && sudo asterisk -rx 'pjsip reload'
```

## 🌐 Proveedores Soportados

| Proveedor | Dominio | Detección Automática |
|-----------|---------|---------------------|
| Twilio | sip.twilio.com | ✅ |
| Plivo | sip.plivo.com | ✅ |
| SignalWire | sip.signalwire.com | ✅ |
| Telnyx | sip.telnyx.com | ✅ |
| Vonage | sip.vonage.com | ✅ |
| Custom | Otros dominios | ✅ |

## 📁 Estructura del Proyecto

```
trunkmanager-api/
├── app.js              # Servidor principal de la API
├── package.json         # Dependencias de Node.js
├── install.sh          # Script de instalación
├── examples/           # Plantillas de configuración
│   ├── twilio.conf
│   ├── plivo.conf
│   ├── signalwire.conf
│   ├── telnyx.conf
│   ├── vonage.conf
│   └── custom.conf
└── README.md           # Este archivo
```

## 🚨 Solución de Problemas

### El servicio no inicia
```bash
# Verificar logs
journalctl -u trunkmanager-api -n 50

# Verificar permisos
ls -la /opt/trunkmanager-api/
ls -la /etc/asterisk/trunks/
```

### La API no responde
```bash
# Verificar que el puerto esté abierto
netstat -tlnp | grep 56201

# Verificar firewall
firewall-cmd --list-ports
```

### Error de permisos
```bash
# Corregir permisos
sudo chown -R asterisk:asterisk /opt/trunkmanager-api/
sudo chown asterisk:asterisk /etc/asterisk/trunks/
```

## 📝 Logs

Los logs del servicio se pueden ver con:
```bash
journalctl -u trunkmanager-api -f
```

## 🔄 Actualización

Para actualizar el servicio:
```bash
# Detener servicio
sudo systemctl stop trunkmanager-api

# Ejecutar instalación nuevamente
wget https://raw.githubusercontent.com/UnCarnaval/addtrunkapi-module/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

## 📞 Soporte

Para reportar problemas o solicitar nuevas funcionalidades, crear un issue en el repositorio de GitHub.

---

**Trunk Manager API** - Simplificando la gestión de trunks SIP 🚀