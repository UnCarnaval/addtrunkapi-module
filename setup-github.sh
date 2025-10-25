#!/bin/bash

# Script para inicializar y subir el repositorio a GitHub
# GitHub Repository Setup Script

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
    echo -e "${BLUE}  GitHub Repository Setup${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Configuración del repositorio
REPO_URL="https://github.com/UnCarnaval/addtrunkapi-module.git"
REPO_NAME="addtrunkapi-module"
BRANCH="main"

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  -u, --url URL        URL del repositorio (default: $REPO_URL)"
    echo "  -b, --branch BRANCH  Rama principal (default: $BRANCH)"
    echo "  -f, --force          Forzar inicialización (sobrescribir .git)"
    echo "  -h, --help           Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0"
    echo "  $0 -u https://github.com/otro-usuario/otro-repo.git"
    echo "  $0 -b master"
    echo ""
    echo "Requisitos:"
    echo "  - Git instalado"
    echo "  - Acceso al repositorio GitHub"
    echo "  - Archivos del módulo en el directorio actual"
}

# Función para verificar dependencias
check_dependencies() {
    print_message "Verificando dependencias..."
    
    # Verificar Git
    if ! command -v git &> /dev/null; then
        print_error "Git no está instalado"
        exit 1
    fi
    
    # Verificar archivos del módulo
    local required_files=("module.xml" "install.php" "app.js" "package.json")
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            print_error "Archivo requerido no encontrado: $file"
            exit 1
        fi
    done
    
    print_message "Dependencias verificadas ✓"
}

# Función para inicializar repositorio Git
init_git_repo() {
    print_message "Inicializando repositorio Git..."
    
    # Verificar si ya existe .git
    if [ -d ".git" ] && [ "$FORCE" != "true" ]; then
        print_warning "Repositorio Git ya existe"
        read -p "¿Continuar? (y/N): " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            print_message "Operación cancelada"
            exit 0
        fi
    fi
    
    # Inicializar repositorio
    if [ "$FORCE" = "true" ] && [ -d ".git" ]; then
        rm -rf .git
    fi
    
    git init
    git branch -M "$BRANCH"
    
    print_message "Repositorio Git inicializado ✓"
}

# Función para configurar Git
configure_git() {
    print_message "Configurando Git..."
    
    # Configurar usuario (si no está configurado)
    if ! git config user.name &> /dev/null; then
        print_warning "Configurando usuario Git..."
        read -p "Nombre de usuario Git: " git_user
        git config user.name "$git_user"
    fi
    
    if ! git config user.email &> /dev/null; then
        print_warning "Configurando email Git..."
        read -p "Email Git: " git_email
        git config user.email "$git_email"
    fi
    
    print_message "Git configurado ✓"
}

# Función para agregar archivos
add_files() {
    print_message "Agregando archivos al repositorio..."
    
    # Agregar todos los archivos
    git add .
    
    # Verificar archivos agregados
    local files_count=$(git status --porcelain | wc -l)
    print_message "Archivos agregados: $files_count ✓"
}

# Función para hacer commit inicial
make_initial_commit() {
    print_message "Haciendo commit inicial..."
    
    git commit -m "Initial commit: Trunk Manager Module v1.0.0

- Módulo completo para FreePBX
- Detección automática de proveedores SIP
- API REST para gestión de trunks
- Interfaz web integrada
- Scripts de instalación automática
- Soporte para múltiples proveedores (Twilio, Plivo, SignalWire, Telnyx, Vonage, Custom)
- Documentación completa
- Instalación remota sin acceso físico al servidor"
    
    print_message "Commit inicial creado ✓"
}

# Función para configurar remote
setup_remote() {
    print_message "Configurando remote origin..."
    
    # Verificar si ya existe remote
    if git remote get-url origin &> /dev/null; then
        print_warning "Remote origin ya existe"
        read -p "¿Actualizar URL? (y/N): " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            git remote set-url origin "$REPO_URL"
        fi
    else
        git remote add origin "$REPO_URL"
    fi
    
    print_message "Remote origin configurado: $REPO_URL ✓"
}

# Función para hacer push inicial
push_to_github() {
    print_message "Subiendo a GitHub..."
    
    # Verificar conectividad
    if ! git ls-remote origin &> /dev/null; then
        print_error "No se puede conectar al repositorio remoto"
        print_message "Verifica:"
        print_message "  - URL del repositorio: $REPO_URL"
        print_message "  - Permisos de acceso"
        print_message "  - Conectividad a internet"
        exit 1
    fi
    
    # Hacer push
    git push -u origin "$BRANCH"
    
    print_message "Código subido a GitHub ✓"
}

# Función para crear release
create_release() {
    print_message "Creando release v1.0.0..."
    
    # Crear tag
    git tag -a v1.0.0 -m "Release v1.0.0: Trunk Manager Module

Primera versión estable del módulo Trunk Manager para FreePBX.

Características:
- Detección automática de proveedores SIP
- API REST completa
- Interfaz web integrada
- Instalación automática como servicio
- Soporte para múltiples proveedores
- Documentación completa
- Scripts de instalación remota"
    
    # Subir tag
    git push origin v1.0.0
    
    print_message "Release v1.0.0 creada ✓"
}

# Función para mostrar información post-setup
show_post_setup_info() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Repositorio Configurado${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    print_message "Repositorio GitHub configurado exitosamente"
    echo ""
    echo -e "${YELLOW}Información del repositorio:${NC}"
    echo "• URL: $REPO_URL"
    echo "• Rama principal: $BRANCH"
    echo "• Release: v1.0.0"
    echo ""
    echo -e "${YELLOW}Próximos pasos:${NC}"
    echo "1. Verificar el repositorio en GitHub"
    echo "2. Configurar GitHub Pages (opcional)"
    echo "3. Configurar GitHub Actions"
    echo "4. Configurar Dependabot"
    echo "5. Crear Issues y Pull Requests"
    echo ""
    echo -e "${YELLOW}Comandos útiles:${NC}"
    echo "• Ver estado: git status"
    echo "• Ver logs: git log --oneline"
    echo "• Crear rama: git checkout -b feature/nueva-funcionalidad"
    echo "• Subir cambios: git push origin $BRANCH"
    echo ""
    echo -e "${YELLOW}Documentación:${NC}"
    echo "• README.md - Documentación principal"
    echo "• API_EXAMPLES.md - Ejemplos de uso"
    echo "• CONFIG.md - Configuración avanzada"
    echo "• INSTALL_GUIDE.md - Guía de instalación"
    echo ""
}

# Función principal
main() {
    print_header
    
    print_message "Configurando repositorio GitHub para Trunk Manager Module"
    print_message "Repositorio: $REPO_URL"
    print_message "Rama: $BRANCH"
    echo ""
    
    check_dependencies
    init_git_repo
    configure_git
    add_files
    make_initial_commit
    setup_remote
    push_to_github
    create_release
    show_post_setup_info
    
    print_message "Configuración del repositorio completada exitosamente!"
}

# Procesar argumentos de línea de comandos
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--url)
            REPO_URL="$2"
            shift 2
            ;;
        -b|--branch)
            BRANCH="$2"
            shift 2
            ;;
        -f|--force)
            FORCE="true"
            shift
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
