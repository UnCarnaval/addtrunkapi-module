# 🚀 Instalación en Sangoma 7 - Guía Completa

## ✅ **Solución para Sangoma 7 (CentOS 7 modificado)**

Como Sangoma 7 no permite instalar Git fácilmente, he creado métodos alternativos específicos para tu sistema.

## 🎯 **Método 1: Script Automático (Recomendado)**

### **Descargar y Ejecutar Script**
```bash
# Descargar script de instalación
wget https://raw.githubusercontent.com/UnCarnaval/addtrunkapi-module/main/install-sangoma7.sh

# Hacer ejecutable
chmod +x install-sangoma7.sh

# Ejecutar instalación
sudo ./install-sangoma7.sh
```

### **¿Qué hace el script?**
- ✅ Descarga el módulo directamente desde GitHub
- ✅ Instala Node.js y dependencias automáticamente
- ✅ Configura el servicio systemd
- ✅ Configura firewall para puerto 56201
- ✅ Inicia el servicio automáticamente

## 🎯 **Método 2: Descarga Manual**

### **Paso 1: Descargar ZIP desde GitHub**
```bash
# Descargar archivo ZIP
cd /tmp
wget https://github.com/UnCarnaval/addtrunkapi-module/archive/refs/heads/main.zip

# Extraer
unzip main.zip
mv addtrunkapi-module-main trunkmanager
```

### **Paso 2: Instalar Manualmente**
```bash
# Crear directorio del módulo
sudo mkdir -p /var/www/html/admin/modules/trunkmanager

# Copiar archivos
sudo cp -r trunkmanager/* /var/www/html/admin/modules/trunkmanager/

# Configurar permisos
sudo chown -R asterisk:asterisk /var/www/html/admin/modules/trunkmanager
sudo chmod -R 755 /var/www/html/admin/modules/trunkmanager
```

### **Paso 3: Instalar Node.js**
```bash
# Instalar Node.js
sudo yum install -y epel-release
sudo yum install -y nodejs npm

# Instalar dependencias
cd /var/www/html/admin/modules/trunkmanager/nodejs
sudo npm install
```

### **Paso 4: Crear Servicio**
```bash
# Crear servicio systemd
sudo tee /etc/systemd/system/trunkmanager-api.service > /dev/null << 'EOF'
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
sudo systemctl daemon-reload
sudo systemctl enable trunkmanager-api
sudo systemctl start trunkmanager-api
```

## 🎯 **Método 3: Desde FreePBX Web**

### **Paso 1: Crear Paquete en tu Máquina Local**
```bash
# En tu máquina local (donde tienes Git)
./create-package.sh
# Esto crea: trunkmanager-1.0.0.tgz
```

### **Paso 2: Subir a Sangoma 7**
```bash
# Subir via SCP
scp trunkmanager-1.0.0.tgz usuario@sangoma-server:/tmp/

# O usar FileZilla/WinSCP
```

### **Paso 3: Instalar desde FreePBX**
1. **Acceder a:** `http://tu-servidor/admin`
2. **Ir a:** Admin → Module Admin
3. **Hacer clic en:** "Upload Module"
4. **Seleccionar:** `trunkmanager-1.0.0.tgz`
5. **Hacer clic en:** "Upload" → "Install"

## 🔧 **Verificación Post-Instalación**

### **Verificar Servicio**
```bash
# Estado del servicio
sudo systemctl status trunkmanager-api

# Verificar API
curl http://localhost:56201/health

# Ver logs
sudo journalctl -u trunkmanager-api -f
```

### **Verificar en FreePBX**
1. **Acceder a:** Admin → Module Admin
2. **Buscar:** "Trunk Manager"
3. **Hacer clic en:** "Install"
4. **Navegar a:** Connectivity → Trunk Manager

## 🆘 **Solución de Problemas en Sangoma 7**

### **Si wget no está disponible:**
```bash
# Instalar wget
sudo yum install -y wget
```

### **Si Node.js no está disponible:**
```bash
# Instalar Node.js
sudo yum install -y epel-release
sudo yum install -y nodejs npm
```

### **Si hay problemas de permisos:**
```bash
# Configurar permisos correctos
sudo chown -R asterisk:asterisk /var/www/html/admin/modules/trunkmanager
sudo chmod -R 755 /var/www/html/admin/modules/trunkmanager
```

### **Si el servicio no inicia:**
```bash
# Ver logs detallados
sudo journalctl -u trunkmanager-api -n 50

# Reiniciar servicio
sudo systemctl restart trunkmanager-api
```

## 🎯 **Recomendación para Sangoma 7**

### **Opción Más Fácil:**
**Usar el script automático** - Descarga e instala todo automáticamente

### **Opción Manual:**
**Descargar ZIP** y seguir los pasos manuales

### **Opción Web:**
**Crear paquete .tgz** y subir desde FreePBX

## 📋 **Checklist de Instalación**

- [ ] Script descargado y ejecutado
- [ ] Node.js instalado
- [ ] Archivos del módulo copiados
- [ ] Permisos configurados
- [ ] Servicio systemd creado
- [ ] Servicio iniciado
- [ ] API respondiendo
- [ ] Módulo instalado desde FreePBX

## 🚀 **Comandos Rápidos**

### **Instalación Automática:**
```bash
wget https://raw.githubusercontent.com/UnCarnaval/addtrunkapi-module/main/install-sangoma7.sh
chmod +x install-sangoma7.sh
sudo ./install-sangoma7.sh
```

### **Verificación:**
```bash
sudo systemctl status trunkmanager-api
curl http://localhost:56201/health
```

### **Logs:**
```bash
sudo journalctl -u trunkmanager-api -f
```

¡Con estos métodos puedes instalar el módulo en Sangoma 7 sin necesidad de Git! 🎉
