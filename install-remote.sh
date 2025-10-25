#!/bin/bash

# Script de Instalación Remota - Trunk Manager Module
# Este script instala el módulo en un servidor remoto sin acceso físico

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
    echo -e "${BLUE}  Instalación Remota - Trunk Manager${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Configuración del servidor
SERVER=""
USER=""
MODULE_DIR="/var/www/html/admin/modules/trunkmanager"
LOCAL_MODULE_DIR="./trunkmanager"

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  -s, --server SERVER    Servidor de destino (requerido)"
    echo "  -u, --user USER        Usuario SSH (requerido)"
    echo "  -p, --port PORT        Puerto SSH (opcional, default: 22)"
    echo "  -k, --key KEYFILE      Archivo de clave SSH (opcional)"
    echo "  -d, --dir DIRECTORY    Directorio de destino (opcional)"
    echo "  -h, --help             Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 -s mi-servidor.com -u root"
    echo "  $0 -s 192.168.1.100 -u admin -p 2222"
    echo "  $0 -s servidor.com -u usuario -k ~/.ssh/id_rsa"
    echo ""
    echo "Requisitos:"
    echo "  - Acceso SSH al servidor"
    echo "  - Permisos sudo en el servidor"
    echo "  - Carpeta 'trunkmanager' en el directorio actual"
}

# Función para verificar dependencias locales
check_local_dependencies() {
    print_message "Verificando dependencias locales..."
    
    # Verificar que existe la carpeta del módulo
    if [ ! -d "$LOCAL_MODULE_DIR" ]; then
        print_error "No se encuentra la carpeta '$LOCAL_MODULE_DIR'"
        print_message "Asegúrate de estar en el directorio correcto"
        exit 1
    fi
    
    # Verificar archivos esenciales
    local required_files=("module.xml" "install.php" "app.js" "package.json")
    for file in "${required_files[@]}"; do
        if [ ! -f "$LOCAL_MODULE_DIR/$file" ]; then
            print_error "Archivo requerido no encontrado: $file"
            exit 1
        fi
    done
    
    # Verificar comandos necesarios
    local required_commands=("ssh" "scp")
    for cmd in "${required_commands[@]}"; do
        if ! command -v $cmd &> /dev/null; then
            print_error "Comando requerido no encontrado: $cmd"
            exit 1
        fi
    done
    
    print_message "Dependencias locales verificadas ✓"
}

# Función para verificar conectividad SSH
check_ssh_connection() {
    print_message "Verificando conectividad SSH..."
    
    local ssh_cmd="ssh"
    if [ -n "$SSH_KEY" ]; then
        ssh_cmd="$ssh_cmd -i $SSH_KEY"
    fi
    if [ -n "$SSH_PORT" ]; then
        ssh_cmd="$ssh_cmd -p $SSH_PORT"
    fi
    
    if $ssh_cmd -o ConnectTimeout=10 -o BatchMode=yes $USER@$SERVER "echo 'SSH OK'" > /dev/null 2>&1; then
        print_message "Conexión SSH verificada ✓"
    else
        print_error "No se puede conectar al servidor via SSH"
        print_message "Verifica:"
        print_message "  - Servidor: $SERVER"
        print_message "  - Usuario: $USER"
        print_message "  - Puerto: ${SSH_PORT:-22}"
        print_message "  - Clave SSH: ${SSH_KEY:-'por defecto'}"
        exit 1
    fi
}

# Función para verificar dependencias del servidor
check_server_dependencies() {
    print_message "Verificando dependencias del servidor..."
    
    local ssh_cmd="ssh"
    if [ -n "$SSH_KEY" ]; then
        ssh_cmd="$ssh_cmd -i $SSH_KEY"
    fi
    if [ -n "$SSH_PORT" ]; then
        ssh_cmd="$ssh_cmd -p $SSH_PORT"
    fi
    
    # Verificar que el servidor tiene los comandos necesarios
    local required_server_commands=("node" "npm" "systemctl" "asterisk")
    for cmd in "${required_server_commands[@]}"; do
        if ! $ssh_cmd $USER@$SERVER "which $cmd" > /dev/null 2>&1; then
            print_warning "Comando no encontrado en el servidor: $cmd"
        fi
    done
    
    # Verificar directorio de FreePBX
    if ! $ssh_cmd $USER@$SERVER "test -d /var/www/html/admin/modules" > /dev/null 2>&1; then
        print_error "Directorio de FreePBX no encontrado: /var/www/html/admin/modules"
        exit 1
    fi
    
    print_message "Dependencias del servidor verificadas ✓"
}

# Función para crear directorio en el servidor
create_server_directory() {
    print_message "Creando directorio en el servidor..."
    
    local ssh_cmd="ssh"
    if [ -n "$SSH_KEY" ]; then
        ssh_cmd="$ssh_cmd -i $SSH_KEY"
    fi
    if [ -n "$SSH_PORT" ]; then
        ssh_cmd="$ssh_cmd -p $SSH_PORT"
    fi
    
    $ssh_cmd $USER@$SERVER "sudo mkdir -p $MODULE_DIR"
    $ssh_cmd $USER@$SERVER "sudo chown $USER:$USER $MODULE_DIR"
    
    print_message "Directorio creado: $MODULE_DIR ✓"
}

# Función para copiar archivos al servidor
copy_files_to_server() {
    print_message "Copiando archivos al servidor..."
    
    local scp_cmd="scp"
    if [ -n "$SSH_KEY" ]; then
        scp_cmd="$scp_cmd -i $SSH_KEY"
    fi
    if [ -n "$SSH_PORT" ]; then
        scp_cmd="$scp_cmd -P $SSH_PORT"
    fi
    
    # Copiar todos los archivos del módulo
    $scp_cmd -r $LOCAL_MODULE_DIR/* $USER@$SERVER:$MODULE_DIR/
    
    print_message "Archivos copiados ✓"
}

# Función para ejecutar instalación en el servidor
run_server_installation() {
    print_message "Ejecutando instalación en el servidor..."
    
    local ssh_cmd="ssh"
    if [ -n "$SSH_KEY" ]; then
        ssh_cmd="$ssh_cmd -i $SSH_KEY"
    fi
    if [ -n "$SSH_PORT" ]; then
        ssh_cmd="$ssh_cmd -p $SSH_PORT"
    fi
    
    # Ejecutar script de instalación
    $ssh_cmd $USER@$SERVER "cd $MODULE_DIR && sudo ./install.sh"
    
    print_message "Instalación completada ✓"
}

# Función para verificar instalación
verify_installation() {
    print_message "Verificando instalación..."
    
    local ssh_cmd="ssh"
    if [ -n "$SSH_KEY" ]; then
        ssh_cmd="$ssh_cmd -i $SSH_KEY"
    fi
    if [ -n "$SSH_PORT" ]; then
        ssh_cmd="$ssh_cmd -p $SSH_PORT"
    fi
    
    # Verificar servicio
    if $ssh_cmd $USER@$SERVER "systemctl is-active --quiet trunkmanager-api" > /dev/null 2>&1; then
        print_message "Servicio activo ✓"
    else
        print_warning "Servicio no activo"
    fi
    
    # Verificar API
    if $ssh_cmd $USER@$SERVER "curl -s http://localhost:56201/health" > /dev/null 2>&1; then
        print_message "API respondiendo ✓"
    else
        print_warning "API no responde (puede tardar unos segundos)"
    fi
    
    # Verificar archivos
    if $ssh_cmd $USER@$SERVER "test -f $MODULE_DIR/module.xml" > /dev/null 2>&1; then
        print_message "Archivos del módulo instalados ✓"
    else
        print_error "Archivos del módulo no encontrados"
    fi
}

# Función para mostrar información post-instalación
show_post_install_info() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Instalación Remota Completada${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    print_message "El módulo Trunk Manager ha sido instalado remotamente"
    echo ""
    echo -e "${YELLOW}Próximos pasos:${NC}"
    echo "1. Acceder a FreePBX: http://$SERVER/admin"
    echo "2. Ir a Admin → Module Admin"
    echo "3. Buscar 'Trunk Manager' y hacer clic en 'Install'"
    echo "4. Navegar a Connectivity → Trunk Manager"
    echo ""
    echo -e "${YELLOW}Información del servicio:${NC}"
    echo "• Servidor: $SERVER"
    echo "• Servicio: trunkmanager-api"
    echo "• Puerto API: 56201"
    echo "• URL API: http://$SERVER:56201"
    echo ""
    echo -e "${YELLOW}Comandos útiles:${NC}"
    echo "• Ver estado: ssh $USER@$SERVER 'systemctl status trunkmanager-api'"
    echo "• Ver logs: ssh $USER@$SERVER 'journalctl -u trunkmanager-api -f'"
    echo "• Reiniciar: ssh $USER@$SERVER 'sudo systemctl restart trunkmanager-api'"
    echo ""
}

# Función principal
main() {
    print_header
    
    # Verificar que se proporcionaron los parámetros requeridos
    if [ -z "$SERVER" ] || [ -z "$USER" ]; then
        print_error "Servidor y usuario son requeridos"
        show_help
        exit 1
    fi
    
    print_message "Iniciando instalación remota..."
    print_message "Servidor: $SERVER"
    print_message "Usuario: $USER"
    print_message "Puerto: ${SSH_PORT:-22}"
    print_message "Clave SSH: ${SSH_KEY:-'por defecto'}"
    print_message "Directorio destino: $MODULE_DIR"
    echo ""
    
    check_local_dependencies
    check_ssh_connection
    check_server_dependencies
    create_server_directory
    copy_files_to_server
    run_server_installation
    verify_installation
    show_post_install_info
    
    print_message "Instalación remota completada exitosamente!"
}

# Procesar argumentos de línea de comandos
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--server)
            SERVER="$2"
            shift 2
            ;;
        -u|--user)
            USER="$2"
            shift 2
            ;;
        -p|--port)
            SSH_PORT="$2"
            shift 2
            ;;
        -k|--key)
            SSH_KEY="$2"
            shift 2
            ;;
        -d|--dir)
            MODULE_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "Opción desconocida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Ejecutar función principal
main
