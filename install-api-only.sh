#!/bin/bash

# Script Simple para Sangoma 7 - Solo API Trunk Manager
# Instala solo el servicio Node.js sin módulo de FreePBX

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
    echo -e "${BLUE}  Trunk Manager API - Sangoma 7${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Verificar si es root
if [[ $EUID -ne 0 ]]; then
    print_error "Este script debe ejecutarse como root"
    print_message "Usa: sudo $0"
    exit 1
fi

print_header

# Configuración
API_DIR="/opt/trunkmanager-api"
EXAMPLES_DIR="$API_DIR/examples"
GITHUB_URL="https://github.com/UnCarnaval/addtrunkapi-module/archive/refs/heads/main.zip"
TEMP_DIR="/tmp/trunkmanager-install"

print_message "Iniciando instalación de Trunk Manager API..."

# Crear directorio temporal
print_message "Creando directorio temporal..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Descargar módulo
print_message "Descargando API desde GitHub..."
wget -O trunkmanager.zip "$GITHUB_URL"
unzip trunkmanager.zip
cd addtrunkapi-module-main

# Crear estructura de directorios
print_message "Creando estructura de directorios..."
mkdir -p "$API_DIR"
mkdir -p "$EXAMPLES_DIR"
mkdir -p "/etc/asterisk/trunks"

# Copiar archivos de la API
print_message "Copiando archivos de la API..."
cp app.js "$API_DIR/"
cp package.json "$API_DIR/"

# Copiar plantillas de configuración
cp examples/*.conf "$EXAMPLES_DIR/"

# Configurar permisos
print_message "Configurando permisos..."
chown -R asterisk:asterisk "$API_DIR"
chmod -R 755 "$API_DIR"
chown asterisk:asterisk /etc/asterisk/trunks
chmod 755 /etc/asterisk/trunks

# Instalar Node.js si no está instalado
if ! command -v node &> /dev/null; then
    print_message "Instalando Node.js..."
    yum install -y epel-release
    yum install -y nodejs npm
fi

# Instalar dependencias de Node.js
print_message "Instalando dependencias de Node.js..."
cd "$API_DIR"
npm install --production

# Crear servicio systemd
print_message "Creando servicio systemd..."

# Verificar si el usuario asterisk existe
if ! id "asterisk" &>/dev/null; then
    print_message "Usuario asterisk no encontrado, creando usuario..."
    useradd -r -s /bin/false asterisk
fi

cat > /etc/systemd/system/trunkmanager-api.service << 'EOF'
[Unit]
Description=Trunk Manager API Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node /opt/trunkmanager-api/app.js
WorkingDirectory=/opt/trunkmanager-api
Restart=always
RestartSec=10
User=root
Group=root
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# Habilitar y iniciar servicio
print_message "Habilitando servicio..."
systemctl daemon-reload
systemctl enable trunkmanager-api
systemctl start trunkmanager-api

# Configurar firewall
if command -v firewall-cmd &> /dev/null; then
    print_message "Configurando firewall..."
    firewall-cmd --permanent --add-port=56201/tcp
    firewall-cmd --reload
fi

# Verificar instalación
print_message "Verificando instalación..."
sleep 3

if systemctl is-active --quiet trunkmanager-api; then
    print_message "✓ Servicio activo"
else
    print_error "✗ Servicio no activo"
    print_message "Verificando logs:"
    journalctl -u trunkmanager-api --no-pager -n 10
fi

if curl -s http://localhost:56201/health > /dev/null; then
    print_message "✓ API respondiendo"
else
    print_message "⚠ API no responde (puede tardar unos segundos)"
fi

# Limpiar archivos temporales
rm -rf "$TEMP_DIR"

# Mostrar información final
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Instalación Completada${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
print_message "El Trunk Manager API ha sido instalado correctamente"
echo ""
echo -e "${YELLOW}Información del servicio:${NC}"
echo "• Servicio: trunkmanager-api"
echo "• Puerto API: 56201"
echo "• Directorio: $API_DIR"
echo "• Estado: $(systemctl is-active trunkmanager-api)"
echo ""
echo -e "${YELLOW}Uso de la API:${NC}"
echo "• Health Check: curl http://$(hostname -I | awk '{print $1}'):56201/health"
echo "• Agregar Trunk: POST http://$(hostname -I | awk '{print $1}'):56201/add-trunk"
echo "• Eliminar Trunk: DELETE http://$(hostname -I | awk '{print $1}'):56201/delete-trunk/{nombre}"
echo ""
echo -e "${YELLOW}Comandos útiles:${NC}"
echo "• Ver estado: systemctl status trunkmanager-api"
echo "• Ver logs: journalctl -u trunkmanager-api -f"
echo "• Reiniciar: systemctl restart trunkmanager-api"
echo "• Detener: systemctl stop trunkmanager-api"
echo ""

print_message "Instalación completada exitosamente!"
