#!/bin/bash

# Script para Reparar Módulo Roto en FreePBX (Sin MySQL)
# Versión simplificada que no requiere contraseña de MySQL

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Reparar Módulo Roto FreePBX${NC}"
    echo -e "${BLUE}  (Sin MySQL - Versión Simple)${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Verificar si es root
if [[ $EUID -ne 0 ]]; then
    print_error "Este script debe ejecutarse como root"
    print_message "Usa: sudo $0"
    exit 1
fi

print_header

print_message "Reparando módulo Trunk Manager roto (sin MySQL)..."

# 1. Detener servicio
print_message "1. Deteniendo servicio..."
if systemctl is-active --quiet trunkmanager-api; then
    systemctl stop trunkmanager-api
    print_message "✓ Servicio detenido"
fi

# 2. Deshabilitar servicio
if systemctl is-enabled --quiet trunkmanager-api; then
    systemctl disable trunkmanager-api
    print_message "✓ Servicio deshabilitado"
fi

# 3. Eliminar archivo de servicio
if [ -f "/etc/systemd/system/trunkmanager-api.service" ]; then
    rm -f /etc/systemd/system/trunkmanager-api.service
    systemctl daemon-reload
    print_message "✓ Archivo de servicio eliminado"
fi

# 4. Eliminar directorio del módulo completamente
MODULE_DIR="/var/www/html/admin/modules/trunkmanager"
if [ -d "$MODULE_DIR" ]; then
    rm -rf "$MODULE_DIR"
    print_message "✓ Directorio del módulo eliminado"
fi

# 5. Limpiar cache de FreePBX
print_message "2. Limpiando cache de FreePBX..."
rm -rf /var/www/html/admin/modules/_cache/*
rm -rf /var/www/html/admin/modules/.module_installer_cache/*
print_message "✓ Cache limpiado"

# 6. Descargar módulo corregido
print_message "3. Descargando módulo corregido..."
cd /tmp
rm -rf addtrunkapi-module-main main.zip
wget -O main.zip https://github.com/UnCarnaval/addtrunkapi-module/archive/refs/heads/main.zip
unzip main.zip
print_message "✓ Módulo descargado"

# 7. Instalar módulo corregido
print_message "4. Instalando módulo corregido..."
mkdir -p "$MODULE_DIR"
cp -r addtrunkapi-module-main/* "$MODULE_DIR/"

# 8. Configurar permisos correctos
print_message "5. Configurando permisos..."
chown -R asterisk:asterisk "$MODULE_DIR"
chmod -R 755 "$MODULE_DIR"

# 9. Instalar dependencias Node.js
print_message "6. Instalando dependencias Node.js..."
cd "$MODULE_DIR/nodejs"
npm install --production

# 10. Crear servicio systemd corregido
print_message "7. Creando servicio systemd..."
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
User=root
Group=root
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# 11. Habilitar y iniciar servicio
print_message "8. Iniciando servicio..."
systemctl daemon-reload
systemctl enable trunkmanager-api
systemctl start trunkmanager-api

# 12. Verificar instalación
print_message "9. Verificando instalación..."
sleep 3

if systemctl is-active --quiet trunkmanager-api; then
    print_message "✓ Servicio activo"
else
    print_error "✗ Servicio no activo"
    print_message "Logs del servicio:"
    journalctl -u trunkmanager-api --no-pager -n 10
fi

if curl -s http://localhost:56201/health > /dev/null; then
    print_message "✓ API respondiendo"
else
    print_warning "⚠ API no responde (puede tardar unos segundos)"
fi

# 13. Limpiar archivos temporales
rm -rf /tmp/addtrunkapi-module-main /tmp/main.zip

# 14. Mostrar información final
echo ""
print_message "Reparación completada!"
echo ""
print_message "Próximos pasos:"
echo "1. Acceder a FreePBX: http://$(hostname -I | awk '{print $1}')/admin"
echo "2. Ir a Admin → Module Admin"
echo "3. Buscar 'Trunk Manager' y hacer clic en 'Install'"
echo "4. El módulo debería aparecer como 'Stable' en lugar de 'Broken'"
echo ""
print_message "Nota: Esta versión no usa base de datos MySQL"
print_message "El módulo funcionará correctamente sin configuración de BD"
echo ""
