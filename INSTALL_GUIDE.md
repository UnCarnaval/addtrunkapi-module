# 🚀 Guía de Instalación - Trunk Manager Module

## ✅ Instalación Rápida (Recomendado)

### Para Sangoma 7 / CentOS 7

```bash
# Instalación completa en 3 comandos
wget https://raw.githubusercontent.com/UnCarnaval/addtrunkapi-module/main/install-sangoma7.sh
chmod +x install-sangoma7.sh
sudo ./install-sangoma7.sh
```

### Instalación desde Cero (Limpieza + Instalación)

```bash
# Si tienes problemas o instalación anterior
wget https://raw.githubusercontent.com/UnCarnaval/addtrunkapi-module/main/install-complete.sh
chmod +x install-complete.sh
sudo ./install-complete.sh
```

## 📋 Verificación Post-Instalación

### 1. Verificar Servicio
```bash
sudo systemctl status trunkmanager-api
```

### 2. Verificar API
```bash
curl http://localhost:56201/health
```

### 3. Instalar desde FreePBX
1. **Acceder a:** `http://tu-servidor/admin`
2. **Ir a:** Admin → Module Admin
3. **Buscar:** "Trunk Manager"
4. **Hacer clic en:** "Install"
5. **Navegar a:** Connectivity → Trunk Manager

## 🔧 Comandos Útiles

### Gestión del Servicio
```bash
# Ver estado
sudo systemctl status trunkmanager-api

# Reiniciar servicio
sudo systemctl restart trunkmanager-api

# Ver logs
sudo journalctl -u trunkmanager-api -f

# Habilitar inicio automático
sudo systemctl enable trunkmanager-api
```

### Pruebas de la API
```bash
# Verificar salud de la API
curl http://localhost:56201/health

# Probar detección de proveedor
curl http://localhost:56201/detect-provider/sip.telnyx.com

# Agregar trunk de prueba
curl -X POST http://localhost:56201/add-trunk \
  -H "Content-Type: application/json" \
  -d '{
    "username": "test_user",
    "password": "test_pass",
    "server": "sip.telnyx.com"
  }'
```

## 🆘 Solución de Problemas

### Servicio no inicia
```bash
# Ver logs detallados
sudo journalctl -u trunkmanager-api -n 50

# Verificar configuración
sudo systemctl cat trunkmanager-api
```

### API no responde
```bash
# Verificar puerto
sudo netstat -tlnp | grep 56201

# Verificar proceso
ps aux | grep node
```

### Problemas de permisos
```bash
# Configurar permisos correctos
sudo chown -R asterisk:asterisk /var/www/html/admin/modules/trunkmanager
sudo chmod -R 755 /var/www/html/admin/modules/trunkmanager
```

## 📊 Información del Sistema

### Archivos del Módulo
- **Directorio:** `/var/www/html/admin/modules/trunkmanager`
- **API Node.js:** `/var/www/html/admin/modules/trunkmanager/nodejs/app.js`
- **Servicio:** `/etc/systemd/system/trunkmanager-api.service`
- **Logs:** `journalctl -u trunkmanager-api`

### Puertos
- **API REST:** 56201
- **FreePBX:** 80/443 (puerto web)

### Usuarios
- **Servicio:** root (para evitar problemas de permisos)
- **Archivos:** asterisk:asterisk

## 🎯 Próximos Pasos

1. ✅ **Instalar módulo** usando los comandos de arriba
2. ✅ **Verificar servicio** con `systemctl status`
3. ✅ **Probar API** con `curl http://localhost:56201/health`
4. ✅ **Instalar desde FreePBX** en Module Admin
5. ✅ **Configurar trunks** en Connectivity → Trunk Manager

¡Listo! El módulo estará funcionando correctamente. 🎉