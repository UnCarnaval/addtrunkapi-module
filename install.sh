#!/bin/bash

# Script de instalación simple para Trunk Manager API
# Solo instala el servicio Node.js con permisos correctos

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
    echo -e "${BLUE}  Trunk Manager API${NC}"
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

print_message "Instalando Trunk Manager API..."

# Crear directorio temporal
print_message "Descargando desde GitHub..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Descargar API
wget -O trunkmanager.zip "$GITHUB_URL"
unzip trunkmanager.zip
cd addtrunkapi-module-main

# Crear directorios
print_message "Creando estructura de directorios..."
mkdir -p "$API_DIR"
mkdir -p "$EXAMPLES_DIR"
mkdir -p "/etc/asterisk/trunks"

# Copiar archivos
print_message "Copiando archivos..."
cp app.js "$API_DIR/"
cp package.json "$API_DIR/"
cp examples/*.conf "$EXAMPLES_DIR/"

# Instalar Node.js si no está instalado
if ! command -v node &> /dev/null; then
    print_message "Instalando Node.js..."
    yum install -y epel-release
    yum install -y nodejs npm
fi

# Instalar dependencias
print_message "Instalando dependencias..."
cd "$API_DIR"
npm install --production

# Crear usuario asterisk si no existe
if ! id "asterisk" &>/dev/null; then
    print_message "Creando usuario asterisk..."
    useradd -r -s /bin/false asterisk
fi

# Configurar permisos
print_message "Configurando permisos..."
chown -R asterisk:asterisk "$API_DIR"
chmod -R 755 "$API_DIR"
# El directorio trunks debe permitir que root escriba archivos legibles por asterisk
chown root:asterisk /etc/asterisk/trunks
chmod 775 /etc/asterisk/trunks

# Verificar y agregar include en pjsip_custom.conf si no existe
print_message "Configurando pjsip_custom.conf..."
PJSIP_CUSTOM="/etc/asterisk/pjsip_custom.conf"
INCLUDE_LINE="#include trunks/*.conf"

if [ -f "$PJSIP_CUSTOM" ]; then
    if ! grep -q "include trunks/\*\.conf" "$PJSIP_CUSTOM"; then
        echo "" >> "$PJSIP_CUSTOM"
        echo "$INCLUDE_LINE" >> "$PJSIP_CUSTOM"
        print_message "✓ Agregada línea include en pjsip_custom.conf"
    else
        print_message "✓ Línea include ya existe en pjsip_custom.conf"
    fi
else
    # Si el archivo no existe, crearlo
    echo "$INCLUDE_LINE" > "$PJSIP_CUSTOM"
    chmod 644 "$PJSIP_CUSTOM"
    print_message "✓ Creado pjsip_custom.conf con include"
fi

# Configurar límites de systemd para Asterisk
print_message "Configurando límites de systemd para Asterisk..."
ASTERISK_LIMITS_DIR="/etc/systemd/system/asterisk.service.d"
ASTERISK_LIMITS_FILE="$ASTERISK_LIMITS_DIR/limits.conf"

mkdir -p "$ASTERISK_LIMITS_DIR"

cat > "$ASTERISK_LIMITS_FILE" << 'LIMITS_EOF'
[Service]
LimitNOFILE=65535
LimitNPROC=65535
LIMITS_EOF

chmod 644 "$ASTERISK_LIMITS_FILE"
print_message "✓ Configurados límites de systemd para Asterisk (LimitNOFILE=65535, LimitNPROC=65535)"

# Recargar systemd y reiniciar Asterisk si está instalado
if systemctl list-units --type=service --all | grep -q "asterisk.service"; then
    print_message "Recargando systemd y reiniciando Asterisk..."
    systemctl daemon-reexec
    systemctl daemon-reload
    if systemctl is-active --quiet asterisk; then
        systemctl restart asterisk
        print_message "✓ Asterisk reiniciado con nuevos límites"
    else
        print_message "⚠ Asterisk no está activo, límites se aplicarán al iniciar"
    fi
else
    print_message "⚠ Servicio de Asterisk no encontrado, límites se aplicarán cuando se instale"
fi

# Crear servicio systemd
print_message "Creando servicio systemd..."
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
print_message "Iniciando servicio..."
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
print_message "Trunk Manager API instalado correctamente"
echo ""
echo -e "${YELLOW}Información:${NC}"
echo "• Servicio: trunkmanager-api"
echo "• Puerto: 56201"
echo "• Directorio: $API_DIR"
echo "• Estado: $(systemctl is-active trunkmanager-api)"
echo ""
echo -e "${YELLOW}Uso de la API:${NC}"
echo "• Health: curl http://$(hostname -I | awk '{print $1}'):56201/health"
echo "• Agregar: POST http://$(hostname -I | awk '{print $1}'):56201/add-trunk"
echo "• Eliminar: DELETE http://$(hostname -I | awk '{print $1}'):56201/delete-trunk/{nombre}"
echo ""
echo -e "${YELLOW}Comandos útiles:${NC}"
echo "• Estado: systemctl status trunkmanager-api"
echo "• Logs: journalctl -u trunkmanager-api -f"
echo "• Reiniciar: systemctl restart trunkmanager-api"
echo ""

print_message "Instalación completada exitosamente!"
