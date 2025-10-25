# Ejemplos de Uso - Trunk Manager API

## Detección Automática de Proveedores

La API ahora detecta automáticamente el tipo de proveedor basándose en el servidor SIP. Solo necesitas enviar:

```json
{
  "username": "tu_usuario",
  "password": "tu_contraseña", 
  "server": "sip.proveedor.com"
}
```

## Ejemplos por Proveedor

### Twilio
```bash
curl -X POST http://localhost:56201/add-trunk \
  -H "Content-Type: application/json" \
  -d '{
    "username": "tu_account_sid",
    "password": "tu_auth_token",
    "server": "sip.twilio.com"
  }'
```

### Plivo
```bash
curl -X POST http://localhost:56201/add-trunk \
  -H "Content-Type: application/json" \
  -d '{
    "username": "tu_auth_id",
    "password": "tu_auth_token",
    "server": "sip.plivo.com"
  }'
```

### SignalWire
```bash
curl -X POST http://localhost:56201/add-trunk \
  -H "Content-Type: application/json" \
  -d '{
    "username": "tu_space_id",
    "password": "tu_project_token",
    "server": "sip.signalwire.com"
  }'
```

### Telnyx
```bash
curl -X POST http://localhost:56201/add-trunk \
  -H "Content-Type: application/json" \
  -d '{
    "username": "tu_connection_id",
    "password": "tu_api_key",
    "server": "sip.telnyx.com"
  }'
```

### Vonage
```bash
curl -X POST http://localhost:56201/add-trunk \
  -H "Content-Type: application/json" \
  -d '{
    "username": "tu_api_key",
    "password": "tu_api_secret",
    "server": "sip.vonage.com"
  }'
```

### Custom (Proveedor Personalizado)
```bash
curl -X POST http://localhost:56201/add-trunk \
  -H "Content-Type: application/json" \
  -d '{
    "username": "mi_usuario",
    "password": "mi_contraseña",
    "server": "sip.miproveedor.com"
  }'
```

## Verificar Detección de Proveedor

Antes de crear el trunk, puedes verificar qué proveedor será detectado:

```bash
# Verificar detección
curl http://localhost:56201/detect-provider/sip.telnyx.com

# Respuesta esperada:
{
  "server": "sip.telnyx.com",
  "detected_provider": "telnyx",
  "message": "Proveedor detectado: telnyx"
}
```

## Respuesta de la API

Cuando agregues un trunk exitosamente, recibirás:

```json
{
  "message": "Trunk Trunk_ABC123 agregado y recargado correctamente.",
  "trunk": "telnyx_Trunk_ABC123",
  "detected_provider": "telnyx",
  "server": "sip.telnyx.com"
}
```

## Endpoints Disponibles

### POST /add-trunk
Agrega un nuevo trunk con detección automática de proveedor.

**Parámetros requeridos:**
- `username` (string): Usuario del proveedor SIP
- `password` (string): Contraseña del proveedor SIP  
- `server` (string): Servidor SIP (ej: sip.telnyx.com)

### GET /detect-provider/:server
Detecta el tipo de proveedor basándose en el servidor.

**Parámetros:**
- `server` (string): Servidor SIP a analizar

### DELETE /delete-trunk/:trunkName
Elimina un trunk existente.

**Parámetros:**
- `trunkName` (string): Nombre del trunk a eliminar

### GET /health
Verifica el estado de la API.

## Ventajas de la Detección Automática

✅ **Más fácil de usar** - Solo 3 parámetros en lugar de 4
✅ **Menos errores** - No hay que recordar tipos de proveedor
✅ **Más inteligente** - Detecta automáticamente la configuración correcta
✅ **Compatible** - Funciona con todos los proveedores soportados
✅ **Extensible** - Fácil agregar nuevos proveedores

## Migración desde Versión Anterior

Si tenías código que enviaba el campo `type`, simplemente elimínalo:

```bash
# Antes (versión anterior)
curl -X POST http://localhost:56201/add-trunk \
  -H "Content-Type: application/json" \
  -d '{
    "username": "usuario",
    "password": "contraseña",
    "server": "sip.telnyx.com",
    "type": "telnyx"
  }'

# Ahora (nueva versión)
curl -X POST http://localhost:56201/add-trunk \
  -H "Content-Type: application/json" \
  -d '{
    "username": "usuario", 
    "password": "contraseña",
    "server": "sip.telnyx.com"
  }'
```

El campo `type` ahora se ignora y se detecta automáticamente.