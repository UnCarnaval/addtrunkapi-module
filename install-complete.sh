#!/bin/bash

# Script de Reinstalación Completa para Trunk Manager Module
# Limpia instalación anterior e instala desde cero

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
    echo -e "${BLUE}  Reinstalación Completa Trunk Manager${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Verificar si es root
if [[ $EUID -ne 0 ]]; then
    print_error "Este script debe ejecutarse como root"
    print_message "Usa: sudo $0"
    exit 1
fi

print_header

print_message "Iniciando reinstalación completa..."

# FASE 1: LIMPIEZA
print_message "FASE 1: Limpieza de instalación anterior"

# Detener servicio
if systemctl is-active --quiet trunkmanager-api; then
    systemctl stop trunkmanager-api
    print_message "✓ Servicio detenido"
fi

# Deshabilitar servicio
if systemctl is-enabled --quiet trunkmanager-api; then
    systemctl disable trunkmanager-api
    print_message "✓ Servicio deshabilitado"
fi

# Eliminar archivo de servicio
if [ -f "/etc/systemd/system/trunkmanager-api.service" ]; then
    rm -f /etc/systemd/system/trunkmanager-api.service
    systemctl daemon-reload
    print_message "✓ Archivo de servicio eliminado"
fi

# Eliminar directorio del módulo
MODULE_DIR="/var/www/html/admin/modules/trunkmanager"
if [ -d "$MODULE_DIR" ]; then
    rm -rf "$MODULE_DIR"
    print_message "✓ Directorio del módulo eliminado"
fi

# Limpiar archivos temporales
TEMP_DIRS=(
    "/tmp/trunkmanager-install"
    "/tmp/addtrunkapi-module-main"
    "/tmp/trunkmanager.zip"
    "/tmp/main.zip"
)

for dir in "${TEMP_DIRS[@]}"; do
    if [ -e "$dir" ]; then
        rm -rf "$dir"
        print_message "✓ Archivo temporal eliminado: $dir"
    fi
done

# Limpiar procesos Node.js
pkill -f "node.*app.js" 2>/dev/null || true
print_message "✓ Procesos Node.js limpiados"

print_message "✓ Limpieza completada"
echo ""

# FASE 2: INSTALACIÓN
print_message "FASE 2: Instalación limpia"

# Configuración
NODEJS_DIR="$MODULE_DIR/nodejs"
EXAMPLES_DIR="$NODEJS_DIR/examples"
GITHUB_URL="https://github.com/UnCarnaval/addtrunkapi-module/archive/refs/heads/main.zip"
TEMP_DIR="/tmp/trunkmanager-install"

# Crear directorio temporal
print_message "Creando directorio temporal..."
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Descargar módulo
print_message "Descargando módulo desde GitHub..."
wget -O trunkmanager.zip "$GITHUB_URL"
unzip trunkmanager.zip
cd addtrunkapi-module-main

# Crear estructura de directorios
print_message "Creando estructura de directorios..."
mkdir -p "$MODULE_DIR"
mkdir -p "$NODEJS_DIR"
mkdir -p "$EXAMPLES_DIR"
mkdir -p "/etc/asterisk/trunks"

# Copiar archivos del módulo
print_message "Copiando archivos del módulo..."
cp module.xml "$MODULE_DIR/"
cp install.php "$MODULE_DIR/"
cp uninstall.php "$MODULE_DIR/"
cp config.php "$MODULE_DIR/"
cp functions.php "$MODULE_DIR/"
cp security.php "$MODULE_DIR/"

# Copiar archivos opcionales
if [ -f "README.md" ]; then
    cp README.md "$MODULE_DIR/"
fi
if [ -f "LICENSE" ]; then
    cp LICENSE "$MODULE_DIR/"
fi

# Copiar archivos Node.js
cp app.js "$NODEJS_DIR/"
cp package.json "$NODEJS_DIR/"

# Copiar plantillas de configuración
cp examples/*.conf "$EXAMPLES_DIR/"

# Configurar permisos
print_message "Configurando permisos..."
chown -R asterisk:asterisk "$MODULE_DIR"
chmod -R 755 "$MODULE_DIR"
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
cd "$NODEJS_DIR"
npm install --production

# Crear usuario asterisk si no existe
if ! id "asterisk" &>/dev/null; then
    print_message "Creando usuario asterisk..."
    useradd -r -s /bin/false asterisk
fi

# Crear servicio systemd
print_message "Creando servicio systemd..."
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
    print_message "Logs del servicio:"
    journalctl -u trunkmanager-api --no-pager -n 10
fi

if curl -s http://localhost:56201/health > /dev/null; then
    print_message "✓ API respondiendo"
else
    print_warning "⚠ API no responde (puede tardar unos segundos)"
fi

# Limpiar archivos temporales
rm -rf "$TEMP_DIR"

# Mostrar información final
echo ""
print_message "Reinstalación completada exitosamente!"
echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo "1. Acceder a FreePBX: http://$(hostname -I | awk '{print $1}')/admin"
echo "2. Ir a Admin → Module Admin"
echo "3. Buscar 'Trunk Manager' y hacer clic en 'Install'"
echo "4. Navegar a Connectivity → Trunk Manager"
echo ""
echo -e "${YELLOW}Información del servicio:${NC}"
echo "• Servicio: trunkmanager-api"
echo "• Puerto API: 56201"
echo "• Estado: $(systemctl is-active trunkmanager-api)"
echo ""
echo -e "${YELLOW}Comandos útiles:${NC}"
echo "• Ver estado: systemctl status trunkmanager-api"
echo "• Ver logs: journalctl -u trunkmanager-api -f"
echo "• Reiniciar: systemctl restart trunkmanager-api"
echo "• Probar API: curl http://localhost:56201/health"
echo ""
