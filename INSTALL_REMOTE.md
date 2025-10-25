# Instalación Remota - Trunk Manager Module

## Métodos de Instalación Sin Acceso Físico al Servidor

### Método 1: Instalación desde FreePBX (Recomendado)

#### Opción A: Subir Archivo .tgz
1. **Crear paquete del módulo:**
   ```bash
   tar -czf trunkmanager-1.0.0.tgz trunkmanager/
   ```

2. **Subir a FreePBX:**
   - Acceder a **Admin → Module Admin → Upload Module**
   - Seleccionar el archivo `trunkmanager-1.0.0.tgz`
   - Hacer clic en **"Upload"**
   - Hacer clic en **"Install"**

#### Opción B: Instalación desde URL
1. **Hostear el módulo en un servidor web:**
   ```bash
   # Subir a GitHub, GitLab, o servidor web
   wget https://tu-servidor.com/trunkmanager-1.0.0.tgz
   ```

2. **Instalar desde FreePBX:**
   - Admin → Module Admin → Upload Module
   - Usar URL del archivo .tgz

### Método 2: Instalación via SSH/SCP

#### Desde tu máquina local:
```bash
# Copiar archivos via SCP
scp -r trunkmanager/ usuario@servidor:/var/www/html/admin/modules/

# Conectar via SSH y ejecutar instalación
ssh usuario@servidor "cd /var/www/html/admin/modules/trunkmanager && sudo ./install.sh"
```

#### Con clave SSH configurada:
```bash
# Copiar y ejecutar en un comando
scp -r trunkmanager/ usuario@servidor:/var/www/html/admin/modules/ && \
ssh usuario@servidor "cd /var/www/html/admin/modules/trunkmanager && sudo ./install.sh"
```

### Método 3: Instalación via FTP/SFTP

#### Usando cliente FTP:
1. **Conectar al servidor** con FileZilla, WinSCP, etc.
2. **Navegar a:** `/var/www/html/admin/modules/`
3. **Subir carpeta:** `trunkmanager/`
4. **Ejecutar instalación** via SSH o terminal web

#### Usando línea de comandos FTP:
```bash
# Subir archivos
ftp servidor.com
cd /var/www/html/admin/modules/
put -r trunkmanager/
quit

# Ejecutar instalación
ssh usuario@servidor "cd /var/www/html/admin/modules/trunkmanager && sudo ./install.sh"
```

### Método 4: Instalación via Panel de Control

#### cPanel/WHM:
1. **File Manager** → `/public_html/admin/modules/`
2. **Upload** carpeta `trunkmanager/`
3. **Terminal** → Ejecutar script de instalación

#### Plesk:
1. **File Manager** → `/httpdocs/admin/modules/`
2. **Upload** archivos del módulo
3. **SSH Terminal** → Ejecutar instalación

### Método 5: Instalación Automática via Script

#### Crear script de instalación remota:
```bash
#!/bin/bash
# install-remote.sh

SERVER="tu-servidor.com"
USER="tu-usuario"
MODULE_DIR="/var/www/html/admin/modules/trunkmanager"

echo "Instalando Trunk Manager remotamente..."

# Crear directorio si no existe
ssh $USER@$SERVER "sudo mkdir -p $MODULE_DIR"

# Copiar archivos
scp -r trunkmanager/* $USER@$SERVER:$MODULE_DIR/

# Ejecutar instalación
ssh $USER@$SERVER "cd $MODULE_DIR && sudo ./install.sh"

echo "Instalación completada!"
```

#### Ejecutar:
```bash
chmod +x install-remote.sh
./install-remote.sh
```

### Método 6: Instalación via Docker/Container

#### Si el servidor usa Docker:
```bash
# Crear imagen con el módulo
docker build -t trunkmanager-module .

# Copiar archivos al contenedor
docker cp trunkmanager/ container_name:/var/www/html/admin/modules/

# Ejecutar instalación dentro del contenedor
docker exec container_name bash -c "cd /var/www/html/admin/modules/trunkmanager && ./install.sh"
```

### Método 7: Instalación via API/Webhook

#### Crear endpoint de instalación:
```php
<?php
// install-api.php - Subir al servidor
if ($_POST['action'] === 'install_trunkmanager') {
    $module_url = $_POST['module_url'];
    
    // Descargar módulo
    $zip = file_get_contents($module_url);
    file_put_contents('/tmp/trunkmanager.tgz', $zip);
    
    // Extraer
    exec('cd /var/www/html/admin/modules && tar -xzf /tmp/trunkmanager.tgz');
    
    // Instalar
    exec('cd /var/www/html/admin/modules/trunkmanager && ./install.sh');
    
    echo json_encode(['status' => 'success']);
}
?>
```

#### Usar desde tu máquina:
```bash
curl -X POST http://tu-servidor.com/install-api.php \
  -d "action=install_trunkmanager&module_url=https://tu-servidor.com/trunkmanager.tgz"
```

## Recomendación por Tipo de Acceso

### ✅ **Tienes acceso SSH:**
**Método 2** - Instalación via SCP/SSH (más rápido y seguro)

### ✅ **Solo acceso web a FreePBX:**
**Método 1** - Subir archivo .tgz desde Admin → Module Admin

### ✅ **Tienes acceso FTP/SFTP:**
**Método 3** - Subir archivos y ejecutar instalación via SSH

### ✅ **Tienes panel de control:**
**Método 4** - Usar File Manager + Terminal

### ✅ **Quieres automatización completa:**
**Método 5** - Script de instalación remota

## Verificación Post-Instalación

Después de cualquier método, verificar:

```bash
# Via SSH
ssh usuario@servidor "systemctl status trunkmanager-api"

# Via web
curl http://tu-servidor.com:56201/health

# Via FreePBX
Admin → Connectivity → Trunk Manager
```

## Troubleshooting Remoto

### Si la instalación falla:
```bash
# Ver logs
ssh usuario@servidor "journalctl -u trunkmanager-api -n 50"

# Verificar permisos
ssh usuario@servidor "ls -la /var/www/html/admin/modules/trunkmanager/"

# Reinstalar
ssh usuario@servidor "cd /var/www/html/admin/modules/trunkmanager && sudo ./install.sh"
```

¿Cuál de estos métodos prefieres usar? ¿Tienes acceso SSH, FTP, o solo web?
