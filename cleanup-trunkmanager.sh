#!/bin/bash

# Script de Limpieza Completa para Trunk Manager Module
# Limpia instalaciones anteriores y prepara para reinstalación

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
    echo -e "${BLUE}  Limpieza Completa Trunk Manager${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Verificar si es root
if [[ $EUID -ne 0 ]]; then
    print_error "Este script debe ejecutarse como root"
    print_message "Usa: sudo $0"
    exit 1
fi

print_header

print_message "Iniciando limpieza completa..."

# 1. Detener y deshabilitar servicio
print_message "1. Deteniendo servicio..."
if systemctl is-active --quiet trunkmanager-api; then
    systemctl stop trunkmanager-api
    print_message "✓ Servicio detenido"
else
    print_message "✓ Servicio ya detenido"
fi

if systemctl is-enabled --quiet trunkmanager-api; then
    systemctl disable trunkmanager-api
    print_message "✓ Servicio deshabilitado"
else
    print_message "✓ Servicio ya deshabilitado"
fi

# 2. Eliminar archivo de servicio
print_message "2. Eliminando archivo de servicio..."
if [ -f "/etc/systemd/system/trunkmanager-api.service" ]; then
    rm -f /etc/systemd/system/trunkmanager-api.service
    systemctl daemon-reload
    print_message "✓ Archivo de servicio eliminado"
else
    print_message "✓ Archivo de servicio no existe"
fi

# 3. Eliminar directorio del módulo
print_message "3. Eliminando directorio del módulo..."
MODULE_DIR="/var/www/html/admin/modules/trunkmanager"
if [ -d "$MODULE_DIR" ]; then
    rm -rf "$MODULE_DIR"
    print_message "✓ Directorio del módulo eliminado"
else
    print_message "✓ Directorio del módulo no existe"
fi

# 4. Eliminar archivos temporales
print_message "4. Eliminando archivos temporales..."
TEMP_DIRS=(
    "/tmp/trunkmanager-install"
    "/tmp/addtrunkapi-module-main"
    "/tmp/trunkmanager.zip"
    "/tmp/main.zip"
)

for dir in "${TEMP_DIRS[@]}"; do
    if [ -e "$dir" ]; then
        rm -rf "$dir"
        print_message "✓ Eliminado: $dir"
    fi
done

# 5. Eliminar archivos de instalación
print_message "5. Eliminando scripts de instalación..."
INSTALL_SCRIPTS=(
    "install-sangoma7.sh"
    "install-sangoma7-simple.sh"
    "diagnose-trunkmanager.sh"
    "fix-trunkmanager.sh"
)

for script in "${INSTALL_SCRIPTS[@]}"; do
    if [ -f "/tmp/$script" ]; then
        rm -f "/tmp/$script"
        print_message "✓ Eliminado: /tmp/$script"
    fi
    if [ -f "./$script" ]; then
        rm -f "./$script"
        print_message "✓ Eliminado: ./$script"
    fi
done

# 6. Limpiar procesos Node.js huérfanos
print_message "6. Limpiando procesos Node.js..."
pkill -f "node.*app.js" 2>/dev/null || true
print_message "✓ Procesos Node.js limpiados"

# 7. Verificar limpieza
print_message "7. Verificando limpieza..."

if [ -d "$MODULE_DIR" ]; then
    print_warning "⚠ Directorio del módulo aún existe"
else
    print_message "✓ Directorio del módulo eliminado"
fi

if [ -f "/etc/systemd/system/trunkmanager-api.service" ]; then
    print_warning "⚠ Archivo de servicio aún existe"
else
    print_message "✓ Archivo de servicio eliminado"
fi

if systemctl list-unit-files | grep -q "trunkmanager-api.service"; then
    print_warning "⚠ Servicio aún registrado en systemd"
else
    print_message "✓ Servicio desregistrado de systemd"
fi

# 8. Mostrar estado final
echo ""
print_message "Limpieza completada!"
echo ""
print_message "Estado del sistema:"
echo "• Servicio: $(systemctl is-active trunkmanager-api 2>/dev/null || echo 'no existe')"
echo "• Puerto 56201: $(netstat -tlnp | grep -q ':56201' && echo 'en uso' || echo 'libre')"
echo "• Directorio módulo: $([ -d "$MODULE_DIR" ] && echo 'existe' || echo 'eliminado')"
echo ""
print_message "Ahora puedes ejecutar una instalación limpia:"
echo "wget https://raw.githubusercontent.com/UnCarnaval/addtrunkapi-module/main/install-sangoma7-simple.sh"
echo "chmod +x install-sangoma7-simple.sh"
echo "sudo ./install-sangoma7-simple.sh"
echo ""
