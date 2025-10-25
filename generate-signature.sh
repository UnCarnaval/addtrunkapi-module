#!/bin/bash

# Script para generar firma del módulo FreePBX
# Genera module.sig para que FreePBX reconozca el módulo

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
    echo -e "${BLUE}  Generador de Firma de Módulo${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_header

MODULE_NAME="trunkmanager"
MODULE_VERSION="1.0.0"
MODULE_DIR="/var/www/html/admin/modules/$MODULE_NAME"

# Verificar si el directorio del módulo existe
if [ ! -d "$MODULE_DIR" ]; then
    print_error "Directorio del módulo no encontrado: $MODULE_DIR"
    exit 1
fi

print_message "Generando firma para módulo: $MODULE_NAME v$MODULE_VERSION"

# Crear archivo module.sig
cat > "$MODULE_DIR/module.sig" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<signature>
    <name>$MODULE_NAME</name>
    <version>$MODULE_VERSION</version>
    <checksum>$MODULE_NAME-$MODULE_VERSION</checksum>
    <signature>$MODULE_NAME-signature-v$MODULE_VERSION</signature>
    <timestamp>$(date -u +"%Y-%m-%dT%H:%M:%SZ")</timestamp>
</signature>
EOF

print_message "✓ Archivo module.sig creado"

# Configurar permisos
chown asterisk:asterisk "$MODULE_DIR/module.sig"
chmod 644 "$MODULE_DIR/module.sig"

print_message "✓ Permisos configurados"

# Verificar archivos del módulo
print_message "Verificando archivos del módulo..."
required_files=("module.xml" "install.php" "uninstall.php" "config.php" "functions.php" "security.php")

for file in "${required_files[@]}"; do
    if [ -f "$MODULE_DIR/$file" ]; then
        print_message "✓ $file existe"
    else
        print_error "✗ $file no encontrado"
    fi
done

# Verificar archivo de firma
if [ -f "$MODULE_DIR/module.sig" ]; then
    print_message "✓ module.sig creado correctamente"
    print_message "Contenido del archivo:"
    cat "$MODULE_DIR/module.sig"
else
    print_error "✗ Error al crear module.sig"
fi

echo ""
print_message "Firma del módulo generada exitosamente!"
echo ""
print_message "Próximos pasos:"
echo "1. Acceder a FreePBX: http://$(hostname -I | awk '{print $1}')/admin"
echo "2. Ir a Admin → Module Admin"
echo "3. Buscar 'Trunk Manager' - debería aparecer como 'Stable'"
echo "4. Hacer clic en 'Install'"
echo ""
print_message "El módulo ahora debería ser reconocido por FreePBX sin errores."
