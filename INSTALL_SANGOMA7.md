# 🚀 Instalación en Sangoma 7 (CentOS 7) - Sin Git

## ✅ **Métodos de Instalación para Sangoma 7**

### **🎯 Método 1: Descarga Directa desde GitHub (Recomendado)**

#### **Opción A: Descargar ZIP desde GitHub**
1. **Ir a:** https://github.com/UnCarnaval/addtrunkapi-module
2. **Hacer clic en:** "Code" → "Download ZIP"
3. **Subir archivo** a tu servidor Sangoma 7
4. **Extraer** en `/var/www/html/admin/modules/`

#### **Opción B: Usar wget/curl (si están disponibles)**
```bash
# Descargar directamente
cd /tmp
wget https://github.com/UnCarnaval/addtrunkapi-module/archive/refs/heads/main.zip

# O con curl
curl -L https://github.com/UnCarnaval/addtrunkapi-module/archive/refs/heads/main.zip -o trunkmanager.zip

# Extraer
unzip main.zip
mv addtrunkapi-module-main trunkmanager
```

### **🎯 Método 2: Instalación desde FreePBX Web**

#### **Paso 1: Crear Paquete de Instalación**
```bash
# En tu máquina local (donde tienes Git)
./create-package.sh
# Esto crea: trunkmanager-1.0.0.tgz
```

#### **Paso 2: Subir a Sangoma 7**
```bash
# Subir archivo via SCP/SFTP
scp trunkmanager-1.0.0.tgz usuario@sangoma-server:/tmp/

# O usar FileZilla/WinSCP para subir el archivo
```

#### **Paso 3: Instalar desde FreePBX**
1. **Acceder a FreePBX:** `http://tu-servidor/admin`
2. **Ir a:** Admin → Module Admin
3. **Hacer clic en:** "Upload Module"
4. **Seleccionar archivo:** `trunkmanager-1.0.0.tgz`
5. **Hacer clic en:** "Upload" → "Install"

### **🎯 Método 3: Instalación Manual Completa**

#### **Paso 1: Crear Estructura de Directorios**
```bash
# Crear directorio del módulo
mkdir -p /var/www/html/admin/modules/trunkmanager

# Configurar permisos
chown -R asterisk:asterisk /var/www/html/admin/modules/trunkmanager
chmod -R 755 /var/www/html/admin/modules/trunkmanager
```

#### **Paso 2: Copiar Archivos Manualmente**
```bash
# Copiar archivos principales
cp module.xml /var/www/html/admin/modules/trunkmanager/
cp install.php /var/www/html/admin/modules/trunkmanager/
cp uninstall.php /var/www/html/admin/modules/trunkmanager/
cp config.php /var/www/html/admin/modules/trunkmanager/
cp functions.php /var/www/html/admin/modules/trunkmanager/
cp security.php /var/www/html/admin/modules/trunkmanager/

# Crear directorio para Node.js
mkdir -p /var/www/html/admin/modules/trunkmanager/nodejs
cp app.js /var/www/html/admin/modules/trunkmanager/nodejs/
cp package.json /var/www/html/admin/modules/trunkmanager/nodejs/

# Copiar plantillas de configuración
mkdir -p /var/www/html/admin/modules/trunkmanager/nodejs/examples
cp examples/*.conf /var/www/html/admin/modules/trunkmanager/nodejs/examples/
```

#### **Paso 3: Instalar Dependencias Node.js**
```bash
# Instalar Node.js si no está instalado
yum install -y epel-release
yum install -y nodejs npm

# Instalar dependencias del módulo
cd /var/www/html/admin/modules/trunkmanager/nodejs
npm install
```

#### **Paso 4: Crear Servicio Systemd**
```bash
# Crear archivo de servicio
cat > /etc/systemd/system/trunkmanager-api.service << 'EOF'
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
EOF

# Habilitar y iniciar servicio
systemctl daemon-reload
systemctl enable trunkmanager-api
systemctl start trunkmanager-api
```

#### **Paso 5: Instalar desde FreePBX**
1. **Acceder a FreePBX:** Admin → Module Admin
2. **Buscar:** "Trunk Manager"
3. **Hacer clic en:** "Install"

### **🎯 Método 4: Usar GitHub Releases**

#### **Descargar Release Directa**
```bash
# Descargar release v1.0.0
cd /tmp
wget https://github.com/UnCarnaval/addtrunkapi-module/archive/refs/tags/v1.0.0.zip

# Extraer
unzip v1.0.0.zip
mv addtrunkapi-module-1.0.0 trunkmanager

# Mover a directorio de módulos
mv trunkmanager /var/www/html/admin/modules/
```

### **🎯 Método 5: Script de Instalación Automática**

#### **Crear Script de Instalación**
```bash
# Crear script de instalación
cat > /tmp/install-trunkmanager.sh << 'EOF'
#!/bin/bash

echo "Instalando Trunk Manager Module..."

# Crear directorio
mkdir -p /var/www/html/admin/modules/trunkmanager

# Descargar desde GitHub (si wget está disponible)
if command -v wget &> /dev/null; then
    echo "Descargando desde GitHub..."
    cd /tmp
    wget https://github.com/UnCarnaval/addtrunkapi-module/archive/refs/heads/main.zip
    unzip main.zip
    mv addtrunkapi-module-main/* /var/www/html/admin/modules/trunkmanager/
    rm -rf addtrunkapi-module-main main.zip
else
    echo "wget no disponible. Instalación manual requerida."
    exit 1
fi

# Configurar permisos
chown -R asterisk:asterisk /var/www/html/admin/modules/trunkmanager
chmod -R 755 /var/www/html/admin/modules/trunkmanager

# Instalar Node.js si no está instalado
if ! command -v node &> /dev/null; then
    echo "Instalando Node.js..."
    yum install -y epel-release
    yum install -y nodejs npm
fi

# Instalar dependencias
cd /var/www/html/admin/modules/trunkmanager/nodejs
npm install

# Crear servicio systemd
cat > /etc/systemd/system/trunkmanager-api.service << 'EOL'
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
EOL

# Habilitar servicio
systemctl daemon-reload
systemctl enable trunkmanager-api
systemctl start trunkmanager-api

echo "Instalación completada!"
echo "Ahora instala el módulo desde FreePBX: Admin → Module Admin"
EOF

# Hacer ejecutable y ejecutar
chmod +x /tmp/install-trunkmanager.sh
/tmp/install-trunkmanager.sh
```

## 🔧 **Verificación Post-Instalación**

### **Verificar Servicio**
```bash
# Verificar estado del servicio
systemctl status trunkmanager-api

# Verificar que la API responde
curl http://localhost:56201/health
```

### **Verificar en FreePBX**
1. **Acceder a:** Admin → Module Admin
2. **Buscar:** "Trunk Manager"
3. **Hacer clic en:** "Install"
4. **Navegar a:** Connectivity → Trunk Manager

## 🆘 **Solución de Problemas en Sangoma 7**

### **Si wget/curl no están disponibles:**
```bash
# Instalar herramientas básicas
yum install -y wget curl unzip
```

### **Si Node.js no está disponible:**
```bash
# Instalar Node.js desde repositorio EPEL
yum install -y epel-release
yum install -y nodejs npm
```

### **Si hay problemas de permisos:**
```bash
# Configurar permisos correctos
chown -R asterisk:asterisk /var/www/html/admin/modules/trunkmanager
chmod -R 755 /var/www/html/admin/modules/trunkmanager
```

## 🎯 **Recomendación para Sangoma 7**

### **Método Más Fácil:**
1. **Descargar ZIP** desde GitHub en tu máquina local
2. **Subir archivo** a Sangoma 7 via SCP/SFTP
3. **Extraer** en `/var/www/html/admin/modules/`
4. **Instalar** desde FreePBX Admin → Module Admin

### **Método Automático:**
1. **Usar script** de instalación automática
2. **Ejecutar** `/tmp/install-trunkmanager.sh`
3. **Instalar** desde FreePBX

¿Cuál método prefieres usar? ¿Tienes acceso a wget/curl en tu Sangoma 7?
