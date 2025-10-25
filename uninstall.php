<?php
/**
 * Trunk Manager Module Uninstallation Script
 * 
 * Este archivo se ejecuta cuando se desinstala el módulo de FreePBX
 */

// Verificar que estamos en el contexto correcto
if (!defined('FREEPBX_IS_AUTH')) {
    die('Not for direct access');
}

// Función principal de desinstalación
function trunkmanager_uninstall() {
    global $db;
    
    // Detener y deshabilitar el servicio
    exec('systemctl stop trunkmanager-api');
    exec('systemctl disable trunkmanager-api');
    
    // Eliminar archivo de servicio systemd
    if (file_exists('/etc/systemd/system/trunkmanager-api.service')) {
        unlink('/etc/systemd/system/trunkmanager-api.service');
        exec('systemctl daemon-reload');
    }
    
    // Eliminar directorio del servicio Node.js
    $nodejs_dir = '/var/www/html/admin/modules/trunkmanager/nodejs';
    if (is_dir($nodejs_dir)) {
        trunkmanager_remove_directory($nodejs_dir);
    }
    
    // Eliminar tabla de configuración
    $sql = "DROP TABLE IF EXISTS trunkmanager_config";
    $db->query($sql);
    
    // Eliminar archivos de configuración de trunks creados por el módulo
    $trunks_dir = '/etc/asterisk/trunks';
    if (is_dir($trunks_dir)) {
        $files = glob($trunks_dir . '/Trunk_*.conf');
        foreach ($files as $file) {
            if (is_file($file)) {
                unlink($file);
            }
        }
    }
    
    // Recargar configuración de Asterisk
    exec("asterisk -rx 'pjsip reload'");
    
    return true;
}

// Función auxiliar para eliminar directorios recursivamente
function trunkmanager_remove_directory($dir) {
    if (!is_dir($dir)) {
        return false;
    }
    
    $files = array_diff(scandir($dir), array('.', '..'));
    foreach ($files as $file) {
        $path = $dir . '/' . $file;
        if (is_dir($path)) {
            trunkmanager_remove_directory($path);
        } else {
            unlink($path);
        }
    }
    return rmdir($dir);
}

// Ejecutar desinstalación
if (trunkmanager_uninstall()) {
    echo "Trunk Manager desinstalado correctamente\n";
} else {
    echo "Error durante la desinstalación de Trunk Manager\n";
}
?>
