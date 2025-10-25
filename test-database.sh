#!/bin/bash

# Script para Probar Conexión a Base de Datos FreePBX
# Verifica que las credenciales funcionen correctamente

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
    echo -e "${BLUE}  Prueba de Base de Datos FreePBX${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_header

# Credenciales de FreePBX
DB_USER="freepbxuser"
DB_PASS="4faiIBd3iPUQ"
DB_HOST="localhost"
DB_NAME="asterisk"

print_message "Probando conexión a base de datos FreePBX..."

# Probar conexión
if mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" "$DB_NAME" -e "SELECT 1;" >/dev/null 2>&1; then
    print_message "✓ Conexión a base de datos exitosa"
    
    # Verificar si la tabla existe
    if mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" "$DB_NAME" -e "SHOW TABLES LIKE 'trunkmanager_config';" | grep -q "trunkmanager_config"; then
        print_message "✓ Tabla trunkmanager_config existe"
        
        # Mostrar contenido de la tabla
        print_message "Contenido de la tabla:"
        mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" "$DB_NAME" -e "SELECT * FROM trunkmanager_config;"
    else
        print_message "ℹ Tabla trunkmanager_config no existe (normal si no se ha instalado)"
    fi
    
    # Crear tabla de prueba
    print_message "Creando tabla de prueba..."
    mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" "$DB_NAME" -e "
        CREATE TABLE IF NOT EXISTS trunkmanager_config (
            id INT AUTO_INCREMENT PRIMARY KEY,
            api_port INT DEFAULT 56201,
            api_enabled TINYINT(1) DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        );"
    
    print_message "✓ Tabla creada exitosamente"
    
    # Insertar datos de prueba
    mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" "$DB_NAME" -e "
        INSERT IGNORE INTO trunkmanager_config (api_port, api_enabled) VALUES (56201, 1);"
    
    print_message "✓ Datos insertados exitosamente"
    
    # Mostrar resultado final
    print_message "Estado final de la tabla:"
    mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" "$DB_NAME" -e "SELECT * FROM trunkmanager_config;"
    
else
    print_error "✗ Error de conexión a base de datos"
    print_message "Verificando credenciales..."
    
    # Probar credenciales alternativas
    print_message "Probando credenciales alternativas..."
    
    # Probar sin contraseña
    if mysql -u "$DB_USER" -h "$DB_HOST" "$DB_NAME" -e "SELECT 1;" >/dev/null 2>&1; then
        print_warning "⚠ La contraseña puede estar vacía"
    fi
    
    # Probar con root
    if mysql -u root -h "$DB_HOST" "$DB_NAME" -e "SELECT 1;" >/dev/null 2>&1; then
        print_warning "⚠ Usuario root funciona sin contraseña"
    fi
    
    print_message "Verifica la configuración en /etc/asterisk/amportal.conf"
fi

echo ""
print_message "Prueba completada!"
echo ""
print_message "Si la conexión fue exitosa, puedes usar:"
echo "wget https://raw.githubusercontent.com/UnCarnaval/addtrunkapi-module/main/fix-broken-module.sh"
echo "chmod +x fix-broken-module.sh"
echo "sudo ./fix-broken-module.sh"
echo ""
