#!/bin/bash

# Script de Instalación para Sangoma 7 (CentOS 7) - Sin Git
# Trunk Manager Module Installation Script

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con colores
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Trunk Manager - Sangoma 7 Installer${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Configuración
MODULE_DIR="/var/www/html/admin/modules/trunkmanager"
NODEJS_DIR="$MODULE_DIR/nodejs"
EXAMPLES_DIR="$NODEJS_DIR/examples"
GITHUB_URL="https://github.com/UnCarnaval/addtrunkapi-module/archive/refs/heads/main.zip"
TEMP_DIR="/tmp/trunkmanager-install"

# Función para verificar si el script se ejecuta como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Este script debe ejecutarse como root"
        exit 1
    fi
}

# Función para verificar dependencias del sistema
check_dependencies() {
    print_message "Verificando dependencias del sistema..."
    
    # Verificar si wget está disponible
    if ! command -v wget &> /dev/null; then
        print_warning "wget no está instalado. Instalando..."
        yum install -y wget
    fi
    
    # Verificar si unzip está disponible
    if ! command -v unzip &> /dev/null; then
        print_warning "unzip no está instalado. Instalando..."
        yum install -y unzip
    fi
    
    # Verificar Node.js
    if ! command -v node &> /dev/null; then
        print_warning "Node.js no está instalado. Instalando..."
        yum install -y epel-release
        yum install -y nodejs npm
    else
        print_message "Node.js está instalado: $(node --version)"
    fi
    
    # Verificar npm
    if ! command -v npm &> /dev/null; then
        print_error "npm no está instalado"
        exit 1
    else
        print_message "npm está instalado: $(npm --version)"
    fi
    
    # Verificar Asterisk
    if ! command -v asterisk &> /dev/null; then
        print_error "Asterisk no está instalado"
        exit 1
    else
        print_message "Asterisk está instalado: $(asterisk -V | head -n1)"
    fi
    
    # Verificar FreePBX
    if [ ! -d "/var/www/html/admin/modules" ]; then
        print_error "FreePBX no parece estar instalado o no se encuentra en la ruta esperada"
        exit 1
    else
        print_message "FreePBX encontrado en /var/www/html/admin/modules"
    fi
}

# Función para crear directorio temporal
create_temp_directory() {
    print_message "Creando directorio temporal..."
    
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    print_message "Directorio temporal creado: $TEMP_DIR"
}

# Función para descargar módulo desde GitHub
download_module() {
    print_message "Descargando módulo desde GitHub..."
    
    cd "$TEMP_DIR"
    
    # Descargar ZIP desde GitHub
    wget -O trunkmanager.zip "$GITHUB_URL"
    
    if [ ! -f "trunkmanager.zip" ]; then
        print_error "Error al descargar el módulo desde GitHub"
        exit 1
    fi
    
    print_message "Módulo descargado correctamente"
}

# Función para extraer módulo
extract_module() {
    print_message "Extrayendo módulo..."
    
    cd "$TEMP_DIR"
    
    # Extraer ZIP
    unzip trunkmanager.zip
    
    # Verificar que se extrajo correctamente
    if [ ! -d "addtrunkapi-module-main" ]; then
        print_error "Error al extraer el módulo"
        exit 1
    fi
    
    print_message "Módulo extraído correctamente"
}

# Función para crear estructura de directorios
create_directories() {
    print_message "Creando estructura de directorios..."
    
    # Crear directorio principal del módulo
    mkdir -p "$MODULE_DIR"
    mkdir -p "$NODEJS_DIR"
    mkdir -p "$EXAMPLES_DIR"
    mkdir -p "/etc/asterisk/trunks"
    
    print_message "Directorios creados correctamente"
}

# Función para copiar archivos del módulo
copy_module_files() {
    print_message "Copiando archivos del módulo..."
    
    cd "$TEMP_DIR/addtrunkapi-module-main"
    
    # Copiar archivos principales del módulo
    cp module.xml "$MODULE_DIR/"
    cp install.php "$MODULE_DIR/"
    cp uninstall.php "$MODULE_DIR/"
    cp config.php "$MODULE_DIR/"
    cp functions.php "$MODULE_DIR/"
    cp security.php "$MODULE_DIR/"
    cp README.md "$MODULE_DIR/"
    cp LICENSE "$MODULE_DIR/"
    
    # Copiar archivos Node.js
    cp app.js "$NODEJS_DIR/"
    cp package.json "$NODEJS_DIR/"
    
    # Copiar archivos de ejemplo
    cp examples/*.conf "$EXAMPLES_DIR/"
    
    print_message "Archivos copiados correctamente"
}

# Función para configurar permisos
set_permissions() {
    print_message "Configurando permisos..."
    
    # Configurar propietario y permisos
    chown -R asterisk:asterisk "$MODULE_DIR"
    chmod -R 755 "$MODULE_DIR"
    
    # Configurar permisos para directorio de trunks
    chown asterisk:asterisk /etc/asterisk/trunks
    chmod 755 /etc/asterisk/trunks
    
    print_message "Permisos configurados correctamente"
}

# Función para instalar dependencias de Node.js
install_nodejs_dependencies() {
    print_message "Instalando dependencias de Node.js..."
    
    cd "$NODEJS_DIR"
    npm install --production
    
    print_message "Dependencias de Node.js instaladas"
}

# Función para crear servicio systemd
create_systemd_service() {
    print_message "Creando servicio systemd..."
    
    # Crear archivo de servicio con sudo
    sudo tee /etc/systemd/system/trunkmanager-api.service > /dev/null << EOF
[Unit]
Description=Trunk Manager API Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node $NODEJS_DIR/app.js
WorkingDirectory=$NODEJS_DIR
Restart=always
RestartSec=10
User=asterisk
Group=asterisk
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF
    
    # Recargar systemd y habilitar servicio
    sudo systemctl daemon-reload
    sudo systemctl enable trunkmanager-api
    
    print_message "Servicio systemd creado y habilitado"
}

# Función para configurar firewall
configure_firewall() {
    print_message "Configurando firewall..."
    
    # Verificar si firewalld está instalado
    if command -v firewall-cmd &> /dev/null; then
        sudo firewall-cmd --permanent --add-port=56201/tcp
        sudo firewall-cmd --reload
        print_message "Firewall configurado para puerto 56201"
    else
        print_warning "firewalld no está instalado, configurar firewall manualmente"
    fi
}

# Función para iniciar el servicio
start_service() {
    print_message "Iniciando servicio..."
    
    sudo systemctl start trunkmanager-api
    
    # Esperar un momento y verificar estado
    sleep 3
    
    if sudo systemctl is-active --quiet trunkmanager-api; then
        print_message "Servicio iniciado correctamente"
    else
        print_error "Error al iniciar el servicio"
        print_message "Verificando logs:"
        sudo journalctl -u trunkmanager-api --no-pager -n 10
        exit 1
    fi
}

# Función para verificar instalación
verify_installation() {
    print_message "Verificando instalación..."
    
    # Verificar servicio
    if sudo systemctl is-active --quiet trunkmanager-api; then
        print_message "✓ Servicio activo"
    else
        print_error "✗ Servicio no activo"
    fi
    
    # Verificar API
    if curl -s http://localhost:56201/health > /dev/null; then
        print_message "✓ API respondiendo"
    else
        print_warning "✗ API no responde (puede tardar unos segundos)"
    fi
    
    # Verificar archivos
    if [ -f "$MODULE_DIR/module.xml" ]; then
        print_message "✓ Archivos del módulo instalados"
    else
        print_error "✗ Archivos del módulo no encontrados"
    fi
}

# Función para limpiar archivos temporales
cleanup_temp_files() {
    print_message "Limpiando archivos temporales..."
    
    rm -rf "$TEMP_DIR"
    
    print_message "Archivos temporales limpiados"
}

# Función para mostrar información post-instalación
show_post_install_info() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Instalación Completada${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    print_message "El módulo Trunk Manager ha sido instalado correctamente en Sangoma 7"
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
    echo "• Estado: $(sudo systemctl is-active trunkmanager-api)"
    echo "• Logs: sudo journalctl -u trunkmanager-api -f"
    echo ""
    echo -e "${YELLOW}Comandos útiles:${NC}"
    echo "• Reiniciar servicio: sudo systemctl restart trunkmanager-api"
    echo "• Ver estado: sudo systemctl status trunkmanager-api"
    echo "• Ver logs: sudo journalctl -u trunkmanager-api -f"
    echo ""
}

# Función principal
main() {
    print_header
    
    check_root
    check_dependencies
    create_temp_directory
    download_module
    extract_module
    create_directories
    copy_module_files
    set_permissions
    install_nodejs_dependencies
    create_systemd_service
    configure_firewall
    start_service
    verify_installation
    cleanup_temp_files
    show_post_install_info
    
    print_message "Instalación completada exitosamente!"
}

# Ejecutar función principal
main "$@"
