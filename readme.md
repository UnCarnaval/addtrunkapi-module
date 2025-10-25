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
- ✅ Gestión de logs y monitoreo
- ✅ **Sin dependencia de FreePBX** - Funciona independientemente

## Requisitos del Sistema

- Node.js 12.x o superior
- npm (Node Package Manager)
- Asterisk con módulos PJSIP habilitados
- Permisos de escritura en `/etc/asterisk/trunks/`
- Sistema operativo Linux (CentOS 7/Sangoma 7 recomendado)

## 🚀 Instalación

### Instalación Solo API (Recomendado)

```bash
# Instalación simple - Solo API sin módulo FreePBX
wget https://raw.githubusercontent.com/UnCarnaval/addtrunkapi-module/main/install-api-only.sh
chmod +x install-api-only.sh
sudo ./install-api-only.sh
```

### Limpiar Módulo FreePBX (Si ya está instalado)

```bash
# Si ya tienes el módulo de FreePBX instalado y quieres solo la API
wget https://raw.githubusercontent.com/UnCarnaval/addtrunkapi-module/main/cleanup-freepbx-module.sh
chmod +x cleanup-freepbx-module.sh
sudo ./cleanup-freepbx-module.sh
```

### Instalación Manual

1. **Descargar módulo:**
```bash
wget https://github.com/UnCarnaval/addtrunkapi-module/archive/refs/heads/main.zip
unzip main.zip
```

2. **Instalar dependencias:**
```bash
sudo yum install -y epel-release nodejs npm
```

3. **Configurar módulo:**
```bash
sudo mkdir -p /var/www/html/admin/modules/trunkmanager
sudo cp -r addtrunkapi-module-main/* /var/www/html/admin/modules/trunkmanager/
sudo chown -R asterisk:asterisk /var/www/html/admin/modules/trunkmanager
```

4. **Instalar desde FreePBX:**
   - Acceder a Admin → Module Admin
   - Buscar "Trunk Manager" e instalar

1. **Crear paquete del módulo:**
   ```bash
   tar -czf trunkmanager-1.0.0.tgz trunkmanager/
   ```

2. **Subir a FreePBX:**
   - Admin → Module Admin → Upload Module
   - Seleccionar el archivo .tgz
   - Hacer clic en "Upload"

## Configuración Inicial

### 1. Verificar Dependencias

Después de la instalación, verificar que todas las dependencias estén instaladas:

```bash
# Verificar Node.js
node --version
npm --version

# Verificar Asterisk
asterisk -V

# Verificar permisos
ls -la /etc/asterisk/trunks/
```

### 2. Configurar el Módulo

1. Acceder a **Connectivity → Trunk Manager**
2. En la pestaña "Configuración":
   - Verificar el puerto de la API (por defecto: 56201)
   - Habilitar la API si no está habilitada
   - Guardar configuración

### 3. Verificar Estado del Servicio

```bash
# Verificar estado del servicio
systemctl status trunkmanager-api

# Ver logs en tiempo real
journalctl -u trunkmanager-api -f

# Reiniciar servicio si es necesario
systemctl restart trunkmanager-api
```

## Uso del Módulo

### Interfaz Web

1. **Acceder al módulo:**
   - Navegar a **Connectivity → Trunk Manager**

2. **Agregar un nuevo trunk:**
   - Ingresar credenciales (usuario, contraseña, servidor)
   - El tipo de proveedor se detecta automáticamente
   - Hacer clic en "Agregar Trunk"

3. **Gestionar trunks existentes:**
   - Ver lista de trunks configurados
   - Eliminar trunks innecesarios
   - Monitorear estado de conexión

### API REST

El módulo expone una API REST en el puerto configurado (por defecto 56201):

#### Agregar Trunk
```bash
curl -X POST http://localhost:56201/add-trunk \
-H "Content-Type: application/json" \
-d '{
    "username": "miusuario",
    "password": "micontraseña",
    "server": "sip.telnyx.com"
  }'
```

#### Detectar Proveedor
```bash
curl http://localhost:56201/detect-provider/sip.telnyx.com
```

#### Eliminar Trunk
```bash
curl -X DELETE http://localhost:56201/delete-trunk/Trunk_ABC123
```

#### Verificar Estado
```bash
curl http://localhost:56201/health
```

## Detección Automática de Proveedores

El módulo detecta automáticamente el tipo de proveedor basándose en el servidor SIP. Solo necesitas proporcionar:

- **Usuario** (username)
- **Contraseña** (password) 
- **Servidor** (server)

### Mapeo de Dominios

| Proveedor | Dominios Detectados |
|-----------|-------------------|
| **Twilio** | twilio.com, sip.twilio.com |
| **Plivo** | plivo.com, sip.plivo.com |
| **SignalWire** | signalwire.com, sip.signalwire.com |
| **Telnyx** | telnyx.com, sip.telnyx.com |
| **Vonage** | vonage.com, sip.vonage.com, nexmo.com |
| **Custom** | Cualquier otro dominio |

### Ejemplos de Detección

```bash
# Twilio
curl http://localhost:56201/detect-provider/sip.twilio.com
# Respuesta: {"detected_provider": "twilio"}

# Telnyx  
curl http://localhost:56201/detect-provider/sip.telnyx.com
# Respuesta: {"detected_provider": "telnyx"}

# Custom
curl http://localhost:56201/detect-provider/sip.miproveedor.com
# Respuesta: {"detected_provider": "custom"}
```

## Tipos de Trunks Soportados

### Custom
Configuración genérica para proveedores SIP estándar.

### Twilio
Configuración optimizada para Twilio SIP Trunking.

### Plivo
Configuración para Plivo Voice API.

### SignalWire
Configuración para SignalWire SIP.

### Vonage
Configuración para Vonage Business Communications.

### Telnyx
Configuración para Telnyx SIP Trunking.

## Solución de Problemas

### El servicio no inicia

1. **Verificar logs:**
   ```bash
   journalctl -u trunkmanager-api -n 50
   ```

2. **Verificar dependencias:**
   ```bash
   which node
   which npm
   ```

3. **Verificar permisos:**
   ```bash
   ls -la /var/www/html/admin/modules/trunkmanager/
   ```

### La API no responde

1. **Verificar puerto:**
   ```bash
   netstat -tlnp | grep 56201
   ```

2. **Verificar firewall:**
   ```bash
   firewall-cmd --list-ports
   ```

3. **Probar conectividad:**
   ```bash
   curl http://localhost:56201/health
   ```

### Trunks no se crean

1. **Verificar permisos en directorio de trunks:**
   ```bash
   ls -la /etc/asterisk/trunks/
   ```

2. **Verificar configuración de Asterisk:**
   ```bash
   asterisk -rx "pjsip show endpoints"
   ```

3. **Verificar logs de Asterisk:**
   ```bash
   tail -f /var/log/asterisk/full
   ```

## Mantenimiento

### Backup de Configuración

```bash
# Backup manual
tar -czf trunkmanager_backup_$(date +%Y%m%d).tar.gz /etc/asterisk/trunks/Trunk_*.conf

# Restaurar backup
tar -xzf trunkmanager_backup_20240101.tar.gz -C /
asterisk -rx "pjsip reload"
```

### Actualización del Módulo

1. Hacer backup de la configuración actual
2. Desinstalar el módulo actual
3. Instalar la nueva versión
4. Restaurar configuración si es necesario

### Limpieza de Logs

```bash
# Limpiar logs del servicio
journalctl --vacuum-time=7d

# Limpiar logs de Asterisk
echo "" > /var/log/asterisk/full
```

## Desinstalación

1. **Desde FreePBX:**
   - Admin → Module Admin
   - Buscar "Trunk Manager"
   - Hacer clic en "Uninstall"

2. **Manual:**
   ```bash
   systemctl stop trunkmanager-api
   systemctl disable trunkmanager-api
   rm -rf /var/www/html/admin/modules/trunkmanager/
   rm -f /etc/systemd/system/trunkmanager-api.service
   ```

## Soporte

Para soporte técnico o reportar problemas:

- **Issues:** [GitHub Issues](https://github.com/tu-usuario/trunkmanager/issues)
- **Documentación:** [Wiki del Proyecto](https://github.com/tu-usuario/trunkmanager/wiki)
- **Email:** soporte@tudominio.com

## Licencia

Este módulo está licenciado bajo GPL v3. Ver archivo LICENSE para más detalles.

## Changelog

### v1.0.0
- Lanzamiento inicial
- Soporte para múltiples proveedores SIP
- Interfaz web integrada
- API REST completa
- Instalación automática como servicio