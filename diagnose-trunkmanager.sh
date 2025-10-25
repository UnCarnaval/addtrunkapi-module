#!/bin/bash

# Script de Diagnóstico para Trunk Manager Module
# Diagnóstico de problemas comunes en Sangoma 7

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
    echo -e "${BLUE}  Diagnóstico Trunk Manager${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_header

# Verificar sistema
print_message "Verificando sistema..."
echo "• Sistema: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "• Kernel: $(uname -r)"
echo "• Arquitectura: $(uname -m)"
echo ""

# Verificar usuarios
print_message "Verificando usuarios..."
if id "asterisk" &>/dev/null; then
    print_message "✓ Usuario asterisk existe"
    echo "  UID: $(id -u asterisk)"
    echo "  GID: $(id -g asterisk)"
    echo "  Shell: $(getent passwd asterisk | cut -d: -f7)"
else
    print_error "✗ Usuario asterisk no existe"
    print_message "Creando usuario asterisk..."
    useradd -r -s /bin/false asterisk
    print_message "✓ Usuario asterisk creado"
fi
echo ""

# Verificar Node.js
print_message "Verificando Node.js..."
if command -v node &> /dev/null; then
    print_message "✓ Node.js instalado: $(node --version)"
else
    print_error "✗ Node.js no instalado"
    print_message "Instalando Node.js..."
    yum install -y epel-release
    yum install -y nodejs npm
fi

if command -v npm &> /dev/null; then
    print_message "✓ npm instalado: $(npm --version)"
else
    print_error "✗ npm no instalado"
fi
echo ""

# Verificar archivos del módulo
print_message "Verificando archivos del módulo..."
MODULE_DIR="/var/www/html/admin/modules/trunkmanager"
NODEJS_DIR="$MODULE_DIR/nodejs"

if [ -d "$MODULE_DIR" ]; then
    print_message "✓ Directorio del módulo existe"
else
    print_error "✗ Directorio del módulo no existe"
fi

if [ -f "$MODULE_DIR/module.xml" ]; then
    print_message "✓ module.xml existe"
else
    print_error "✗ module.xml no existe"
fi

if [ -f "$NODEJS_DIR/app.js" ]; then
    print_message "✓ app.js existe"
else
    print_error "✗ app.js no existe"
fi

if [ -f "$NODEJS_DIR/package.json" ]; then
    print_message "✓ package.json existe"
else
    print_error "✗ package.json no existe"
fi
echo ""

# Verificar dependencias Node.js
print_message "Verificando dependencias Node.js..."
if [ -d "$NODEJS_DIR/node_modules" ]; then
    print_message "✓ node_modules existe"
else
    print_warning "✗ node_modules no existe"
    print_message "Instalando dependencias..."
    cd "$NODEJS_DIR"
    npm install --production
fi
echo ""

# Verificar servicio systemd
print_message "Verificando servicio systemd..."
if [ -f "/etc/systemd/system/trunkmanager-api.service" ]; then
    print_message "✓ Archivo de servicio existe"
else
    print_error "✗ Archivo de servicio no existe"
fi

if systemctl list-unit-files | grep -q "trunkmanager-api.service"; then
    print_message "✓ Servicio registrado en systemd"
else
    print_error "✗ Servicio no registrado en systemd"
fi
echo ""

# Verificar estado del servicio
print_message "Verificando estado del servicio..."
if systemctl is-active --quiet trunkmanager-api; then
    print_message "✓ Servicio activo"
elif systemctl is-failed --quiet trunkmanager-api; then
    print_error "✗ Servicio falló"
    print_message "Últimos logs del servicio:"
    journalctl -u trunkmanager-api --no-pager -n 10
else
    print_warning "⚠ Servicio no activo"
fi
echo ""

# Verificar puerto
print_message "Verificando puerto 56201..."
if netstat -tlnp | grep -q ":56201"; then
    print_message "✓ Puerto 56201 en uso"
else
    print_warning "⚠ Puerto 56201 no en uso"
fi
echo ""

# Verificar API
print_message "Verificando API..."
if curl -s http://localhost:56201/health > /dev/null; then
    print_message "✓ API respondiendo"
    curl -s http://localhost:56201/health | head -n 5
else
    print_warning "⚠ API no responde"
fi
echo ""

# Verificar permisos
print_message "Verificando permisos..."
if [ -d "$MODULE_DIR" ]; then
    echo "• Propietario: $(stat -c '%U:%G' "$MODULE_DIR")"
    echo "• Permisos: $(stat -c '%a' "$MODULE_DIR")"
fi
echo ""

# Verificar firewall
print_message "Verificando firewall..."
if command -v firewall-cmd &> /dev/null; then
    if firewall-cmd --list-ports | grep -q "56201/tcp"; then
        print_message "✓ Puerto 56201 abierto en firewall"
    else
        print_warning "⚠ Puerto 56201 no abierto en firewall"
        print_message "Abriendo puerto..."
        firewall-cmd --permanent --add-port=56201/tcp
        firewall-cmd --reload
    fi
else
    print_warning "⚠ firewalld no instalado"
fi
echo ""

# Soluciones sugeridas
print_message "Soluciones sugeridas:"
echo ""

if ! systemctl is-active --quiet trunkmanager-api; then
    print_message "1. Reiniciar servicio:"
    echo "   systemctl restart trunkmanager-api"
    echo ""
fi

if ! curl -s http://localhost:56201/health > /dev/null; then
    print_message "2. Verificar logs del servicio:"
    echo "   journalctl -u trunkmanager-api -f"
    echo ""
fi

if [ ! -d "$NODEJS_DIR/node_modules" ]; then
    print_message "3. Instalar dependencias:"
    echo "   cd $NODEJS_DIR"
    echo "   npm install --production"
    echo ""
fi

print_message "4. Verificar configuración del servicio:"
echo "   systemctl cat trunkmanager-api"
echo ""

print_message "5. Probar ejecución manual:"
echo "   cd $NODEJS_DIR"
echo "   node app.js"
echo ""

print_message "Diagnóstico completado!"
