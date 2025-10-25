#!/bin/bash

# Script para crear paquete de instalación - Trunk Manager Module
# Crea un archivo .tgz que se puede subir directamente a FreePBX

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
    echo -e "${BLUE}  Crear Paquete de Instalación${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Configuración
MODULE_NAME="trunkmanager"
VERSION="1.0.0"
PACKAGE_NAME="${MODULE_NAME}-${VERSION}.tgz"
SOURCE_DIR="./trunkmanager"
TEMP_DIR="/tmp/trunkmanager-package"

# Función para verificar que existe la carpeta del módulo
check_source_directory() {
    print_message "Verificando carpeta del módulo..."
    
    if [ ! -d "$SOURCE_DIR" ]; then
        print_error "No se encuentra la carpeta '$SOURCE_DIR'"
        print_message "Asegúrate de estar en el directorio correcto"
        exit 1
    fi
    
    # Verificar archivos esenciales
    local required_files=("module.xml" "install.php" "app.js" "package.json")
    for file in "${required_files[@]}"; do
        if [ ! -f "$SOURCE_DIR/$file" ]; then
            print_error "Archivo requerido no encontrado: $file"
            exit 1
        fi
    done
    
    print_message "Carpeta del módulo verificada ✓"
}

# Función para limpiar archivos temporales
cleanup_temp_files() {
    print_message "Limpiando archivos temporales..."
    
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
    
    print_message "Archivos temporales limpiados ✓"
}

# Función para crear directorio temporal
create_temp_directory() {
    print_message "Creando directorio temporal..."
    
    mkdir -p "$TEMP_DIR"
    
    print_message "Directorio temporal creado ✓"
}

# Función para copiar archivos al directorio temporal
copy_files_to_temp() {
    print_message "Copiando archivos al directorio temporal..."
    
    cp -r "$SOURCE_DIR"/* "$TEMP_DIR/"
    
    print_message "Archivos copiados ✓"
}

# Función para crear archivo de información del paquete
create_package_info() {
    print_message "Creando archivo de información del paquete..."
    
    cat > "$TEMP_DIR/PACKAGE_INFO.txt" << EOF
Trunk Manager Module - Paquete de Instalación
=============================================

Versión: $VERSION
Fecha: $(date)
Autor: Tu Nombre

Descripción:
Módulo para gestión automática de trunks SIP mediante API REST.
Incluye detección automática de proveedores y interfaz web integrada.

Características:
- Detección automática de proveedores (Twilio, Plivo, SignalWire, Telnyx, Vonage, Custom)
- API REST para gestión de trunks
- Interfaz web integrada en FreePBX
- Instalación automática como servicio systemd
- Soporte para múltiples proveedores SIP

Instalación:
1. Subir este archivo a FreePBX: Admin → Module Admin → Upload Module
2. Seleccionar el archivo $PACKAGE_NAME
3. Hacer clic en "Upload" y luego "Install"
4. Navegar a Connectivity → Trunk Manager

Uso:
- Solo necesitas proporcionar: usuario, contraseña y servidor
- El tipo de proveedor se detecta automáticamente
- API disponible en puerto 56201

Soporte:
- Documentación: README.md
- Ejemplos: API_EXAMPLES.md
- Configuración: CONFIG.md

Requisitos:
- FreePBX 13.0.0 o superior
- Node.js 12.x o superior
- Asterisk con módulos PJSIP

Licencia: GPL v3
EOF
    
    print_message "Archivo de información creado ✓"
}

# Función para crear el paquete .tgz
create_package() {
    print_message "Creando paquete $PACKAGE_NAME..."
    
    cd "$TEMP_DIR"
    tar -czf "../$PACKAGE_NAME" .
    cd - > /dev/null
    
    # Mover el archivo al directorio actual
    mv "$TEMP_DIR/../$PACKAGE_NAME" "./$PACKAGE_NAME"
    
    print_message "Paquete creado: $PACKAGE_NAME ✓"
}

# Función para verificar el paquete creado
verify_package() {
    print_message "Verificando paquete creado..."
    
    if [ -f "$PACKAGE_NAME" ]; then
        local size=$(du -h "$PACKAGE_NAME" | cut -f1)
        print_message "Archivo creado: $PACKAGE_NAME ($size)"
        
        # Verificar contenido del paquete
        if tar -tzf "$PACKAGE_NAME" | grep -q "module.xml"; then
            print_message "Contenido del paquete verificado ✓"
        else
            print_warning "El paquete puede no contener todos los archivos necesarios"
        fi
    else
        print_error "No se pudo crear el paquete"
        exit 1
    fi
}

# Función para mostrar información del paquete
show_package_info() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Paquete Creado Exitosamente${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    print_message "Paquete: $PACKAGE_NAME"
    print_message "Tamaño: $(du -h "$PACKAGE_NAME" | cut -f1)"
    print_message "Ubicación: $(pwd)/$PACKAGE_NAME"
    echo ""
    echo -e "${YELLOW}Instrucciones de Instalación:${NC}"
    echo "1. Acceder a FreePBX: http://tu-servidor/admin"
    echo "2. Ir a Admin → Module Admin"
    echo "3. Hacer clic en 'Upload Module'"
    echo "4. Seleccionar el archivo: $PACKAGE_NAME"
    echo "5. Hacer clic en 'Upload'"
    echo "6. Hacer clic en 'Install'"
    echo "7. Navegar a Connectivity → Trunk Manager"
    echo ""
    echo -e "${YELLOW}Alternativa - Subir a servidor web:${NC}"
    echo "1. Subir $PACKAGE_NAME a tu servidor web"
    echo "2. Usar URL: http://tu-servidor.com/$PACKAGE_NAME"
    echo "3. Instalar desde URL en FreePBX"
    echo ""
    echo -e "${YELLOW}Contenido del paquete:${NC}"
    tar -tzf "$PACKAGE_NAME" | head -20
    if [ $(tar -tzf "$PACKAGE_NAME" | wc -l) -gt 20 ]; then
        echo "... y $(($(tar -tzf "$PACKAGE_NAME" | wc -l) - 20)) archivos más"
    fi
    echo ""
}

# Función principal
main() {
    print_header
    
    print_message "Creando paquete de instalación para Trunk Manager Module"
    print_message "Versión: $VERSION"
    print_message "Fuente: $SOURCE_DIR"
    print_message "Destino: $PACKAGE_NAME"
    echo ""
    
    check_source_directory
    cleanup_temp_files
    create_temp_directory
    copy_files_to_temp
    create_package_info
    create_package
    cleanup_temp_files
    verify_package
    show_package_info
    
    print_message "Paquete de instalación creado exitosamente!"
}

# Ejecutar función principal
main
