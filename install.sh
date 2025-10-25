#!/bin/bash

# Script de instalación automática para Trunk Manager Module
# FreePBX Module Installation Script

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
    echo -e "${BLUE}  Trunk Manager Module Installer${NC}"
    echo -e "${BLUE}================================${NC}"
}

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
    
    # Verificar Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js no está instalado. Instalando..."
        if command -v yum &> /dev/null; then
            curl -fsSL https://rpm.nodesource.com/setup_16.x | bash -
            yum install -y nodejs
        elif command -v apt-get &> /dev/null; then
            curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
            apt-get install -y nodejs
        else
            print_error "No se pudo instalar Node.js automáticamente"
            exit 1
        fi
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

# Función para crear estructura de directorios
create_directories() {
    print_message "Creando estructura de directorios..."
    
    MODULE_DIR="/var/www/html/admin/modules/trunkmanager"
    NODEJS_DIR="$MODULE_DIR/nodejs"
    EXAMPLES_DIR="$NODEJS_DIR/examples"
    
    mkdir -p "$MODULE_DIR"
    mkdir -p "$NODEJS_DIR"
    mkdir -p "$EXAMPLES_DIR"
    mkdir -p "/etc/asterisk/trunks"
    
    print_message "Directorios creados correctamente"
}

# Función para copiar archivos del módulo
copy_module_files() {
    print_message "Copiando archivos del módulo..."
    
    MODULE_DIR="/var/www/html/admin/modules/trunkmanager"
    
    # Copiar archivos principales del módulo
    cp module.xml "$MODULE_DIR/"
    cp install.php "$MODULE_DIR/"
    cp uninstall.php "$MODULE_DIR/"
    cp config.php "$MODULE_DIR/"
    cp functions.php "$MODULE_DIR/"
    cp README.md "$MODULE_DIR/"
    
    # Copiar archivos Node.js
    cp app.js "$MODULE_DIR/nodejs/"
    cp package.json "$MODULE_DIR/nodejs/"
    
    # Copiar archivos de ejemplo
    cp examples/*.conf "$MODULE_DIR/nodejs/examples/"
    
    print_message "Archivos copiados correctamente"
}

# Función para configurar permisos
set_permissions() {
    print_message "Configurando permisos..."
    
    MODULE_DIR="/var/www/html/admin/modules/trunkmanager"
    
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
    
    NODEJS_DIR="/var/www/html/admin/modules/trunkmanager/nodejs"
    
    cd "$NODEJS_DIR"
    npm install --production
    
    print_message "Dependencias de Node.js instaladas"
}

# Función para crear servicio systemd
create_systemd_service() {
    print_message "Creando servicio systemd..."
    
    NODEJS_DIR="/var/www/html/admin/modules/trunkmanager/nodejs"
    
    cat > /etc/systemd/system/trunkmanager-api.service << EOF
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
    systemctl daemon-reload
    systemctl enable trunkmanager-api
    
    print_message "Servicio systemd creado y habilitado"
}

# Función para configurar firewall
configure_firewall() {
    print_message "Configurando firewall..."
    
    # Verificar si firewalld está instalado
    if command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=56201/tcp
        firewall-cmd --reload
        print_message "Firewall configurado para puerto 56201"
    else
        print_warning "firewalld no está instalado, configurar firewall manualmente"
    fi
}

# Función para iniciar el servicio
start_service() {
    print_message "Iniciando servicio..."
    
    systemctl start trunkmanager-api
    
    # Esperar un momento y verificar estado
    sleep 3
    
    if systemctl is-active --quiet trunkmanager-api; then
        print_message "Servicio iniciado correctamente"
    else
        print_error "Error al iniciar el servicio"
        print_message "Verificando logs:"
        journalctl -u trunkmanager-api --no-pager -n 10
        exit 1
    fi
}

# Función para verificar instalación
verify_installation() {
    print_message "Verificando instalación..."
    
    # Verificar servicio
    if systemctl is-active --quiet trunkmanager-api; then
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
    MODULE_DIR="/var/www/html/admin/modules/trunkmanager"
    if [ -f "$MODULE_DIR/module.xml" ]; then
        print_message "✓ Archivos del módulo instalados"
    else
        print_error "✗ Archivos del módulo no encontrados"
    fi
}

# Función para mostrar información post-instalación
show_post_install_info() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Instalación Completada${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    print_message "El módulo Trunk Manager ha sido instalado correctamente"
    echo ""
    echo -e "${YELLOW}Próximos pasos:${NC}"
    echo "1. Acceder a FreePBX Admin → Module Admin"
    echo "2. Buscar 'Trunk Manager' y hacer clic en 'Install'"
    echo "3. Navegar a Connectivity → Trunk Manager"
    echo "4. Configurar el módulo según tus necesidades"
    echo ""
    echo -e "${YELLOW}Información del servicio:${NC}"
    echo "• Servicio: trunkmanager-api"
    echo "• Puerto API: 56201"
    echo "• Estado: $(systemctl is-active trunkmanager-api)"
    echo "• Logs: journalctl -u trunkmanager-api -f"
    echo ""
    echo -e "${YELLOW}Comandos útiles:${NC}"
    echo "• Reiniciar servicio: systemctl restart trunkmanager-api"
    echo "• Ver estado: systemctl status trunkmanager-api"
    echo "• Ver logs: journalctl -u trunkmanager-api -f"
    echo ""
}

# Función principal
main() {
    print_header
    
    check_root
    check_dependencies
    create_directories
    copy_module_files
    set_permissions
    install_nodejs_dependencies
    create_systemd_service
    configure_firewall
    start_service
    verify_installation
    show_post_install_info
    
    print_message "Instalación completada exitosamente!"
}

# Ejecutar función principal
main "$@"
