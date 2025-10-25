#!/bin/bash

# Script de desinstalación para Trunk Manager Module
# FreePBX Module Uninstallation Script

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
    echo -e "${BLUE}  Trunk Manager Module Uninstaller${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Función para verificar si el script se ejecuta como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Este script debe ejecutarse como root"
        exit 1
    fi
}

# Función para confirmar desinstalación
confirm_uninstall() {
    echo -e "${YELLOW}¿Estás seguro de que quieres desinstalar Trunk Manager?${NC}"
    echo "Esta acción eliminará:"
    echo "• El módulo de FreePBX"
    echo "• El servicio systemd"
    echo "• Los archivos de configuración de trunks"
    echo "• Los logs del módulo"
    echo ""
    read -p "Escribe 'yes' para continuar: " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_message "Desinstalación cancelada"
        exit 0
    fi
}

# Función para crear backup antes de desinstalar
create_backup() {
    print_message "Creando backup de configuración..."
    
    BACKUP_DIR="/var/backups/trunkmanager"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/backup_before_uninstall_$TIMESTAMP.tar.gz"
    
    mkdir -p "$BACKUP_DIR"
    
    # Crear backup de trunks
    tar -czf "$BACKUP_FILE" /etc/asterisk/trunks/Trunk_*.conf 2>/dev/null || true
    
    # Backup de configuración de la base de datos
    if command -v mysqldump &> /dev/null; then
        mysqldump --single-transaction --routines --triggers \
            --where="table_name LIKE 'trunkmanager_%'" \
            information_schema.tables > "$BACKUP_DIR/db_backup_$TIMESTAMP.sql" 2>/dev/null || true
    fi
    
    print_message "Backup creado en: $BACKUP_FILE"
}

# Función para detener el servicio
stop_service() {
    print_message "Deteniendo servicio..."
    
    if systemctl is-active --quiet trunkmanager-api; then
        systemctl stop trunkmanager-api
        print_message "Servicio detenido"
    else
        print_warning "Servicio ya estaba detenido"
    fi
}

# Función para deshabilitar el servicio
disable_service() {
    print_message "Deshabilitando servicio..."
    
    systemctl disable trunkmanager-api
    print_message "Servicio deshabilitado"
}

# Función para eliminar archivo de servicio systemd
remove_systemd_service() {
    print_message "Eliminando archivo de servicio systemd..."
    
    if [ -f "/etc/systemd/system/trunkmanager-api.service" ]; then
        rm -f "/etc/systemd/system/trunkmanager-api.service"
        systemctl daemon-reload
        print_message "Archivo de servicio eliminado"
    else
        print_warning "Archivo de servicio no encontrado"
    fi
}

# Función para eliminar archivos del módulo
remove_module_files() {
    print_message "Eliminando archivos del módulo..."
    
    MODULE_DIR="/var/www/html/admin/modules/trunkmanager"
    
    if [ -d "$MODULE_DIR" ]; then
        rm -rf "$MODULE_DIR"
        print_message "Archivos del módulo eliminados"
    else
        print_warning "Directorio del módulo no encontrado"
    fi
}

# Función para eliminar archivos de configuración de trunks
remove_trunk_configs() {
    print_message "Eliminando archivos de configuración de trunks..."
    
    TRUNKS_DIR="/etc/asterisk/trunks"
    
    if [ -d "$TRUNKS_DIR" ]; then
        # Eliminar solo archivos creados por el módulo
        rm -f "$TRUNKS_DIR"/Trunk_*.conf
        print_message "Archivos de configuración de trunks eliminados"
    else
        print_warning "Directorio de trunks no encontrado"
    fi
}

# Función para limpiar logs
clean_logs() {
    print_message "Limpiando logs..."
    
    # Eliminar logs del servicio
    journalctl --vacuum-time=1s --unit=trunkmanager-api 2>/dev/null || true
    
    # Eliminar archivos de log del módulo
    rm -f /var/log/trunkmanager.log
    
    print_message "Logs limpiados"
}

# Función para eliminar tablas de la base de datos
remove_database_tables() {
    print_message "Eliminando tablas de la base de datos..."
    
    # Obtener credenciales de la base de datos desde FreePBX
    if [ -f "/etc/freepbx.conf" ]; then
        source /etc/freepbx.conf
        
        if [ -n "$AMPDBUSER" ] && [ -n "$AMPDBPASS" ] && [ -n "$AMPDBNAME" ]; then
            mysql -u"$AMPDBUSER" -p"$AMPDBPASS" "$AMPDBNAME" -e "
                DROP TABLE IF EXISTS trunkmanager_config;
                DROP TABLE IF EXISTS trunkmanager_trunks;
                DROP TABLE IF EXISTS trunkmanager_logs;
            " 2>/dev/null || true
            
            print_message "Tablas de la base de datos eliminadas"
        else
            print_warning "No se pudieron obtener credenciales de la base de datos"
        fi
    else
        print_warning "Archivo de configuración de FreePBX no encontrado"
    fi
}

# Función para limpiar reglas de firewall
clean_firewall() {
    print_message "Limpiando reglas de firewall..."
    
    if command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --remove-port=56201/tcp 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
        print_message "Reglas de firewall limpiadas"
    else
        print_warning "firewalld no está instalado"
    fi
}

# Función para recargar configuración de Asterisk
reload_asterisk() {
    print_message "Recargando configuración de Asterisk..."
    
    if command -v asterisk &> /dev/null; then
        asterisk -rx "pjsip reload" 2>/dev/null || true
        print_message "Configuración de Asterisk recargada"
    else
        print_warning "Asterisk no encontrado"
    fi
}

# Función para verificar desinstalación
verify_uninstall() {
    print_message "Verificando desinstalación..."
    
    # Verificar que el servicio no esté activo
    if ! systemctl is-active --quiet trunkmanager-api; then
        print_message "✓ Servicio desinstalado"
    else
        print_error "✗ Servicio aún activo"
    fi
    
    # Verificar que los archivos del módulo no existan
    if [ ! -d "/var/www/html/admin/modules/trunkmanager" ]; then
        print_message "✓ Archivos del módulo eliminados"
    else
        print_error "✗ Archivos del módulo aún existen"
    fi
    
    # Verificar que la API no responda
    if ! curl -s http://localhost:56201/health > /dev/null; then
        print_message "✓ API desinstalada"
    else
        print_warning "✗ API aún responde"
    fi
}

# Función para mostrar información post-desinstalación
show_post_uninstall_info() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Desinstalación Completada${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    print_message "El módulo Trunk Manager ha sido desinstalado correctamente"
    echo ""
    echo -e "${YELLOW}Archivos eliminados:${NC}"
    echo "• Módulo de FreePBX"
    echo "• Servicio systemd"
    echo "• Archivos de configuración de trunks"
    echo "• Logs del módulo"
    echo ""
    echo -e "${YELLOW}Backup creado en:${NC}"
    echo "• /var/backups/trunkmanager/"
    echo ""
    echo -e "${YELLOW}Notas importantes:${NC}"
    echo "• Los trunks creados por el módulo han sido eliminados"
    echo "• La configuración de Asterisk ha sido recargada"
    echo "• Se ha creado un backup antes de la desinstalación"
    echo ""
    echo -e "${YELLOW}Para restaurar desde backup:${NC}"
    echo "• tar -xzf /var/backups/trunkmanager/backup_before_uninstall_*.tar.gz -C /"
    echo "• asterisk -rx 'pjsip reload'"
    echo ""
}

# Función principal
main() {
    print_header
    
    check_root
    confirm_uninstall
    create_backup
    stop_service
    disable_service
    remove_systemd_service
    remove_module_files
    remove_trunk_configs
    clean_logs
    remove_database_tables
    clean_firewall
    reload_asterisk
    verify_uninstall
    show_post_uninstall_info
    
    print_message "Desinstalación completada exitosamente!"
}

# Ejecutar función principal
main "$@"
