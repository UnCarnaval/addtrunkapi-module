# 🚀 Instalación Sin Acceso Físico al Servidor

## ✅ **SÍ, hay varias formas de instalar sin acceso físico!**

### **🎯 Método Más Fácil: Paquete .tgz para FreePBX**

#### **Paso 1: Crear el paquete**
```bash
# Ejecutar script para crear paquete
./create-package.sh
```

#### **Paso 2: Subir a FreePBX**
1. **Acceder a FreePBX:** `http://tu-servidor/admin`
2. **Ir a:** Admin → Module Admin
3. **Hacer clic en:** "Upload Module"
4. **Seleccionar archivo:** `trunkmanager-1.0.0.tgz`
5. **Hacer clic en:** "Upload" → "Install"

### **🔧 Método Avanzado: Instalación Remota via SSH**

#### **Si tienes acceso SSH:**
```bash
# Instalar remotamente
./install-remote.sh -s tu-servidor.com -u tu-usuario

# Con puerto personalizado
./install-remote.sh -s tu-servidor.com -u tu-usuario -p 2222

# Con clave SSH
./install-remote.sh -s tu-servidor.com -u tu-usuario -k ~/.ssh/id_rsa
```

### **📁 Método Manual: Subir Archivos**

#### **Via FTP/SFTP:**
1. **Conectar** con FileZilla, WinSCP, etc.
2. **Navegar a:** `/var/www/html/admin/modules/`
3. **Subir carpeta:** `trunkmanager/`
4. **Ejecutar instalación** via SSH o terminal web

#### **Via Panel de Control (cPanel/Plesk):**
1. **File Manager** → `/public_html/admin/modules/`
2. **Upload** archivos del módulo
3. **Terminal** → Ejecutar script de instalación

### **🌐 Método Web: Subir a Servidor Web**

#### **Opción 1: GitHub/GitLab**
1. **Subir** archivos a repositorio
2. **Crear release** con archivo .tgz
3. **Instalar desde URL** en FreePBX

#### **Opción 2: Servidor Web Propio**
1. **Subir** `trunkmanager-1.0.0.tgz` a tu servidor web
2. **Instalar desde URL:** `http://tu-servidor.com/trunkmanager-1.0.0.tgz`

## 📋 **Requisitos por Método**

| Método | Requisitos | Dificultad |
|--------|------------|------------|
| **Paquete .tgz** | Solo acceso web a FreePBX | ⭐ Fácil |
| **SSH Remoto** | Acceso SSH + permisos sudo | ⭐⭐ Medio |
| **FTP/SFTP** | Acceso FTP + SSH para instalación | ⭐⭐ Medio |
| **Panel Control** | cPanel/Plesk + Terminal | ⭐⭐⭐ Avanzado |
| **Servidor Web** | Servidor web + URL pública | ⭐⭐ Medio |

## 🎯 **Recomendación**

### **Para la mayoría de usuarios:**
**Usa el método del paquete .tgz** - Es el más simple y no requiere acceso SSH.

### **Para usuarios avanzados:**
**Usa la instalación remota via SSH** - Es más rápida y automatizada.

## 🚀 **Instrucciones Rápidas**

### **Método 1: Paquete .tgz (Recomendado)**
```bash
# 1. Crear paquete
./create-package.sh

# 2. Subir a FreePBX
# Admin → Module Admin → Upload Module → Seleccionar trunkmanager-1.0.0.tgz → Upload → Install
```

### **Método 2: SSH Remoto**
```bash
# Instalar directamente
./install-remote.sh -s tu-servidor.com -u tu-usuario
```

### **Método 3: Manual**
```bash
# 1. Subir archivos via FTP/SFTP a /var/www/html/admin/modules/trunkmanager/
# 2. Ejecutar instalación via SSH
ssh tu-usuario@tu-servidor.com "cd /var/www/html/admin/modules/trunkmanager && sudo ./install.sh"
```

## ✅ **Verificación Post-Instalación**

Después de cualquier método:

```bash
# Verificar servicio
curl http://tu-servidor.com:56201/health

# Verificar en FreePBX
# Connectivity → Trunk Manager
```

## 🆘 **Si Algo Sale Mal**

### **Problemas Comunes:**
- **Permisos:** `sudo chown -R asterisk:asterisk /var/www/html/admin/modules/trunkmanager/`
- **Servicio no inicia:** `sudo systemctl restart trunkmanager-api`
- **API no responde:** Verificar puerto 56201 y firewall

### **Logs para Debug:**
```bash
# Via SSH
ssh tu-usuario@tu-servidor.com "journalctl -u trunkmanager-api -f"

# Via web
curl http://tu-servidor.com:56201/health
```

## 🎉 **¡Listo!**

Con cualquiera de estos métodos puedes instalar el módulo **sin acceso físico al servidor**. El método del paquete .tgz es el más simple y funciona en la mayoría de casos.

¿Cuál método prefieres usar?
