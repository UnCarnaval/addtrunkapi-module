#!/bin/bash

# Script de Reparación Rápida para Trunk Manager Module
# Repara problemas comunes en Sangoma 7

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

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Reparación Trunk Manager${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Verificar si es root
if [[ $EUID -ne 0 ]]; then
    print_error "Este script debe ejecutarse como root"
    print_message "Usa: sudo $0"
    exit 1
fi

print_header

MODULE_DIR="/var/www/html/admin/modules/trunkmanager"
NODEJS_DIR="$MODULE_DIR/nodejs"

print_message "Iniciando reparación..."

# 1. Crear usuario asterisk si no existe
print_message "1. Verificando usuario asterisk..."
if ! id "asterisk" &>/dev/null; then
    print_message "Creando usuario asterisk..."
    useradd -r -s /bin/false asterisk
    print_message "✓ Usuario asterisk creado"
else
    print_message "✓ Usuario asterisk existe"
fi

# 2. Instalar Node.js si no está instalado
print_message "2. Verificando Node.js..."
if ! command -v node &> /dev/null; then
    print_message "Instalando Node.js..."
    yum install -y epel-release
    yum install -y nodejs npm
    print_message "✓ Node.js instalado"
else
    print_message "✓ Node.js ya instalado"
fi

# 3. Instalar dependencias
print_message "3. Instalando dependencias..."
if [ -d "$NODEJS_DIR" ]; then
    cd "$NODEJS_DIR"
    npm install --production
    print_message "✓ Dependencias instaladas"
else
    print_error "✗ Directorio Node.js no existe"
    exit 1
fi

# 4. Configurar permisos
print_message "4. Configurando permisos..."
chown -R asterisk:asterisk "$MODULE_DIR"
chmod -R 755 "$MODULE_DIR"
print_message "✓ Permisos configurados"

# 5. Crear servicio systemd corregido
print_message "5. Creando servicio systemd..."
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

# 6. Recargar y reiniciar servicio
print_message "6. Reiniciando servicio..."
systemctl daemon-reload
systemctl enable trunkmanager-api
systemctl restart trunkmanager-api

# 7. Configurar firewall
print_message "7. Configurando firewall..."
if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=56201/tcp
    firewall-cmd --reload
    print_message "✓ Firewall configurado"
else
    print_warning "⚠ firewalld no disponible"
fi

# 8. Verificar instalación
print_message "8. Verificando instalación..."
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

echo ""
print_message "Reparación completada!"
echo ""
print_message "Comandos útiles:"
echo "• Ver estado: systemctl status trunkmanager-api"
echo "• Ver logs: journalctl -u trunkmanager-api -f"
echo "• Reiniciar: systemctl restart trunkmanager-api"
echo "• Probar API: curl http://localhost:56201/health"
echo ""
