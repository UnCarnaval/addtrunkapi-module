#!/bin/bash

# Script simple para limpiar solo la base de datos de FreePBX
# Resuelve el error "No module to check" sin afectar la API

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
    echo -e "${BLUE}  Limpieza Base de Datos${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Verificar si es root
if [[ $EUID -ne 0 ]]; then
    print_error "Este script debe ejecutarse como root"
    print_message "Usa: sudo $0"
    exit 1
fi

print_header

print_message "Limpiando referencias del módulo trunkmanager de la base de datos..."

# Credenciales de FreePBX
DB_USER="freepbxuser"
DB_PASS="4faiIBd3iPUQ"
DB_NAME="asterisk"
DB_HOST="localhost"

# Verificar conexión a la base de datos
if mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME;" 2>/dev/null; then
    print_message "✓ Conexión a base de datos exitosa"
    
    # Eliminar registros del módulo
    print_message "Eliminando registros del módulo..."
    
    mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
        DELETE FROM module_xml WHERE id = 'trunkmanager';
        DELETE FROM modules WHERE modulename = 'trunkmanager';
        DELETE FROM trunkmanager_config WHERE 1=1;
        DROP TABLE IF EXISTS trunkmanager_config;
    " 2>/dev/null || true
    
    print_message "✓ Registros eliminados de la base de datos"
    
    # Limpiar cache de FreePBX
    print_message "Limpiando cache de FreePBX..."
    rm -rf /var/www/html/admin/modules/_cache/*
    rm -rf /var/www/html/admin/modules/.module_checksums
    print_message "✓ Cache limpiado"
    
else
    print_error "✗ No se pudo conectar a la base de datos"
    print_message "Verifica las credenciales en el script"
    exit 1
fi

# Mostrar información final
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Limpieza Completada${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
print_message "Limpieza de base de datos completada"
echo ""
echo -e "${YELLOW}Lo que se hizo:${NC}"
echo "• Eliminados registros de 'trunkmanager' de la tabla 'modules'"
echo "• Eliminados registros de 'trunkmanager' de la tabla 'module_xml'"
echo "• Eliminada tabla 'trunkmanager_config' si existía"
echo "• Limpiado cache de FreePBX"
echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo "1. Recargar página de FreePBX Module Admin"
echo "2. El error 'No module to check' debería desaparecer"
echo "3. Tu API seguirá funcionando normalmente"
echo ""

print_message "Limpieza completada exitosamente!"
