# Trunk Manager Module - Configuración de Ejemplo

## Estructura del Módulo

```
trunkmanager/
├── module.xml              # Metadatos del módulo
├── install.php             # Script de instalación
├── uninstall.php           # Script de desinstalación
├── config.php              # Interfaz principal
├── functions.php           # Funciones auxiliares
├── security.php            # Configuración de seguridad
├── README.md               # Documentación
├── install.sh              # Script de instalación automática
├── uninstall.sh             # Script de desinstalación automática
├── LICENSE                  # Licencia GPL v3
└── nodejs/                  # Directorio de la API Node.js
    ├── app.js              # Servidor API principal
    ├── package.json        # Dependencias Node.js
    └── examples/           # Plantillas de configuración
        ├── custom.conf
        ├── twilio.conf
        ├── plivo.conf
        ├── signalwire.conf
        ├── vonage.conf
        └── telnyx.conf
```

## Configuración del Servicio

### Archivo de Servicio Systemd
```ini
[Unit]
Description=Trunk Manager API Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node /var/www/html/admin/modules/trunkmanager/nodejs/app.js
WorkingDirectory=/var/www/html/admin/modules/trunkmanager/nodejs
Restart=always
RestartSec=10
User=asterisk
Group=asterisk
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

### Configuración de Base de Datos

#### Tabla trunkmanager_config
```sql
CREATE TABLE trunkmanager_config (
    id INT AUTO_INCREMENT PRIMARY KEY,
    api_port INT DEFAULT 56201,
    api_enabled TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

#### Tabla trunkmanager_trunks
```sql
CREATE TABLE trunkmanager_trunks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    trunk_name VARCHAR(100) NOT NULL,
    username VARCHAR(100) NOT NULL,
    server VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    user_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_trunk_name (trunk_name),
    INDEX idx_user_id (user_id),
    INDEX idx_type (type)
);
```

#### Tabla trunkmanager_logs
```sql
CREATE TABLE trunkmanager_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action VARCHAR(100) NOT NULL,
    ip_address VARCHAR(45),
    user_id VARCHAR(50),
    details TEXT,
    INDEX idx_timestamp (timestamp),
    INDEX idx_action (action)
);
```

## Configuración de Seguridad

### IPs Permitidas
```php
$allowed_ips = [
    '127.0.0.1',
    '::1',
    'localhost'
];
```

### Límites de Uso
```php
$limits = [
    'max_trunks_per_user' => 50,
    'api_timeout' => 30,
    'log_api_calls' => true
];
```

## Configuración de Firewall

### Reglas de Firewall (firewalld)
```bash
# Agregar puerto
firewall-cmd --permanent --add-port=56201/tcp
firewall-cmd --reload

# Verificar reglas
firewall-cmd --list-ports
```

### Reglas de Firewall (iptables)
```bash
# Agregar regla
iptables -A INPUT -p tcp --dport 56201 -j ACCEPT

# Guardar reglas
iptables-save > /etc/iptables/rules.v4
```

## Configuración de Asterisk

### Directorio de Trunks
```bash
# Crear directorio si no existe
mkdir -p /etc/asterisk/trunks
chown asterisk:asterisk /etc/asterisk/trunks
chmod 755 /etc/asterisk/trunks
```

### Configuración PJSIP
```ini
# En /etc/asterisk/pjsip.conf
[global]
type=global
endpoint_identifier_order=ip,username,anonymous

[transport-udp]
type=transport
protocol=udp
bind=0.0.0.0:5060
```

## Variables de Entorno

### Variables del Servicio
```bash
NODE_ENV=production
PORT=56201
LOG_LEVEL=info
```

### Variables de FreePBX
```bash
FREEPBX_IS_AUTH=1
AMPDBUSER=freepbxuser
AMPDBPASS=password
AMPDBNAME=asterisk
```

## Logs y Monitoreo

### Ubicaciones de Logs
```bash
# Logs del servicio
journalctl -u trunkmanager-api -f

# Logs del módulo
tail -f /var/log/trunkmanager.log

# Logs de Asterisk
tail -f /var/log/asterisk/full
```

### Comandos de Monitoreo
```bash
# Estado del servicio
systemctl status trunkmanager-api

# Verificar API
curl http://localhost:56201/health

# Verificar trunks en Asterisk
asterisk -rx "pjsip show endpoints"
```

## Backup y Restauración

### Crear Backup
```bash
# Backup de configuración
tar -czf trunkmanager_backup_$(date +%Y%m%d).tar.gz \
    /etc/asterisk/trunks/Trunk_*.conf \
    /var/www/html/admin/modules/trunkmanager/

# Backup de base de datos
mysqldump -u freepbxuser -p asterisk \
    trunkmanager_config trunkmanager_trunks trunkmanager_logs \
    > trunkmanager_db_backup.sql
```

### Restaurar Backup
```bash
# Restaurar archivos
tar -xzf trunkmanager_backup_20240101.tar.gz -C /

# Restaurar base de datos
mysql -u freepbxuser -p asterisk < trunkmanager_db_backup.sql

# Recargar configuración
asterisk -rx "pjsip reload"
```

## Solución de Problemas

### Problemas Comunes

#### Servicio no inicia
```bash
# Verificar logs
journalctl -u trunkmanager-api -n 50

# Verificar dependencias
which node
which npm

# Verificar permisos
ls -la /var/www/html/admin/modules/trunkmanager/
```

#### API no responde
```bash
# Verificar puerto
netstat -tlnp | grep 56201

# Verificar firewall
firewall-cmd --list-ports

# Probar conectividad
curl http://localhost:56201/health
```

#### Trunks no se crean
```bash
# Verificar permisos
ls -la /etc/asterisk/trunks/

# Verificar configuración
asterisk -rx "pjsip show endpoints"

# Verificar logs
tail -f /var/log/asterisk/full
```

### Comandos de Diagnóstico
```bash
# Verificar estado completo
systemctl status trunkmanager-api
curl http://localhost:56201/health
asterisk -rx "pjsip show endpoints"

# Verificar configuración
cat /etc/systemd/system/trunkmanager-api.service
ls -la /var/www/html/admin/modules/trunkmanager/
```
