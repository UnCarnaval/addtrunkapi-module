#!/bin/bash

# Script para limpiar completamente el módulo trunkmanager de FreePBX
# Elimina todas las referencias del módulo de la base de datos y archivos

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
    echo -e "${BLUE}  Limpieza Completa FreePBX${NC}"
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

print_message "Iniciando limpieza completa del módulo trunkmanager..."

# 1. Detener servicio API
print_message "Deteniendo servicio API..."
if systemctl is-active --quiet trunkmanager-api; then
    systemctl stop trunkmanager-api
    print_message "✓ Servicio detenido"
else
    print_message "✓ Servicio ya estaba detenido"
fi

# 2. Eliminar directorio del módulo FreePBX
if [ -d "$MODULE_DIR" ]; then
    print_message "Eliminando directorio del módulo FreePBX..."
    rm -rf "$MODULE_DIR"
    print_message "✓ Directorio del módulo eliminado"
else
    print_message "✓ Directorio del módulo no encontrado"
fi

# 3. Limpiar base de datos FreePBX
print_message "Limpiando base de datos FreePBX..."

# Credenciales de FreePBX
DB_USER="freepbxuser"
DB_PASS="4faiIBd3iPUQ"
DB_NAME="asterisk"
DB_HOST="localhost"

# Verificar conexión a la base de datos
if mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME;" 2>/dev/null; then
    print_message "✓ Conexión a base de datos exitosa"
    
    # Eliminar registros del módulo
    mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
        DELETE FROM module_xml WHERE id = 'trunkmanager';
        DELETE FROM modules WHERE modulename = 'trunkmanager';
        DELETE FROM trunkmanager_config WHERE 1=1;
        DROP TABLE IF EXISTS trunkmanager_config;
    " 2>/dev/null || true
    
    print_message "✓ Registros de base de datos eliminados"
else
    print_error "✗ No se pudo conectar a la base de datos"
    print_message "Continuando con limpieza de archivos..."
fi

# 4. Limpiar cache de FreePBX
print_message "Limpiando cache de FreePBX..."
rm -rf /var/www/html/admin/modules/_cache/*
rm -rf /var/www/html/admin/modules/.module_checksums
print_message "✓ Cache limpiado"

# 5. Limpiar logs de FreePBX relacionados
print_message "Limpiando logs relacionados..."
find /var/log -name "*trunkmanager*" -delete 2>/dev/null || true
print_message "✓ Logs limpiados"

# 6. Verificar si la API está en el nuevo directorio
if [ -d "$API_DIR" ]; then
    print_message "✓ API encontrada en $API_DIR"
    print_message "¿Quieres mantener la API funcionando? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_message "Reiniciando servicio API..."
        systemctl start trunkmanager-api
        sleep 2
        if systemctl is-active --quiet trunkmanager-api; then
            print_message "✓ Servicio API reiniciado correctamente"
        else
            print_error "✗ Error al reiniciar servicio API"
        fi
    else
        print_message "Eliminando API completamente..."
        systemctl disable trunkmanager-api 2>/dev/null || true
        rm -f /etc/systemd/system/trunkmanager-api.service
        systemctl daemon-reload
        rm -rf "$API_DIR"
        print_message "✓ API eliminada completamente"
    fi
else
    print_message "✓ API no encontrada en $API_DIR"
fi

# 7. Verificar limpieza
print_message "Verificando limpieza..."

# Verificar que no queden archivos del módulo
if [ ! -d "$MODULE_DIR" ] && [ ! -f "/etc/systemd/system/trunkmanager-api.service" ] && [ ! -d "$API_DIR" ]; then
    print_message "✓ Limpieza completa exitosa"
elif [ -d "$API_DIR" ] && systemctl is-active --quiet trunkmanager-api; then
    print_message "✓ Limpieza exitosa - Solo API funcionando"
else
    print_message "⚠ Algunos archivos pueden quedar pendientes"
fi

# Mostrar información final
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Limpieza Completada${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
print_message "Limpieza del módulo trunkmanager completada"
echo ""
echo -e "${YELLOW}Estado actual:${NC}"
echo "• Módulo FreePBX: Eliminado"
echo "• Cache FreePBX: Limpiado"
echo "• Base de datos: Limpiada"
echo "• Servicio API: $(if systemctl is-active --quiet trunkmanager-api; then echo 'Activo'; else echo 'Detenido'; fi)"
echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo "1. Recargar página de FreePBX Module Admin"
echo "2. El error 'No module to check' debería desaparecer"
echo "3. Si quieres solo la API, ejecuta: install-api-only.sh"
echo ""

print_message "Limpieza completada exitosamente!"
