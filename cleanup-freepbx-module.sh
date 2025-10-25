#!/bin/bash

# Script para desinstalar módulo de FreePBX y mantener solo la API
# Limpia el módulo de FreePBX pero mantiene el servicio API funcionando

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
    echo -e "${BLUE}  Limpieza Módulo FreePBX${NC}"
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
API_DIR="/opt/trunkmanager-api"

print_message "Limpiando módulo de FreePBX..."

# Verificar si el módulo existe
if [ -d "$MODULE_DIR" ]; then
    print_message "Eliminando directorio del módulo FreePBX..."
    rm -rf "$MODULE_DIR"
    print_message "✓ Módulo FreePBX eliminado"
else
    print_message "✓ Módulo FreePBX no encontrado (ya limpio)"
fi

# Verificar si la API existe en el nuevo directorio
if [ -d "$API_DIR" ]; then
    print_message "✓ API ya instalada en $API_DIR"
else
    print_message "⚠ API no encontrada en $API_DIR"
    print_message "Ejecuta install-api-only.sh para instalar solo la API"
fi

# Verificar estado del servicio
if systemctl is-active --quiet trunkmanager-api; then
    print_message "✓ Servicio API funcionando correctamente"
    print_message "Estado del servicio:"
    systemctl status trunkmanager-api --no-pager -l
else
    print_message "⚠ Servicio API no está activo"
fi

# Mostrar información final
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Limpieza Completada${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
print_message "Módulo de FreePBX eliminado exitosamente"
echo ""
echo -e "${YELLOW}Estado actual:${NC}"
echo "• Módulo FreePBX: Eliminado"
echo "• Servicio API: $(systemctl is-active trunkmanager-api)"
echo "• Puerto API: 56201"
echo ""
echo -e "${YELLOW}Para usar solo la API:${NC}"
echo "• Health Check: curl http://$(hostname -I | awk '{print $1}'):56201/health"
echo "• Agregar Trunk: POST http://$(hostname -I | awk '{print $1}'):56201/add-trunk"
echo "• Eliminar Trunk: DELETE http://$(hostname -I | awk '{print $1}'):56201/delete-trunk/{nombre}"
echo ""

print_message "Limpieza completada!"
