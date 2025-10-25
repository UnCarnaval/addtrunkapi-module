<?php
/**
 * Trunk Manager Module Installation Script
 * 
 * Este archivo se ejecuta cuando se instala el módulo en FreePBX
 */

// Verificar que estamos en el contexto correcto
if (!defined('FREEPBX_IS_AUTH')) {
    die('Not for direct access');
}

// Función principal de instalación
function trunkmanager_install() {
    global $db;
    
    // Crear tabla para almacenar configuración del módulo
    $sql = "CREATE TABLE IF NOT EXISTS trunkmanager_config (
        id INT AUTO_INCREMENT PRIMARY KEY,
        api_port INT DEFAULT 56201,
        api_enabled TINYINT(1) DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )";
    
    $result = $db->query($sql);
    if ($result === false) {
        return false;
    }
    
    // Insertar configuración por defecto
    $sql = "INSERT INTO trunkmanager_config (api_port, api_enabled) VALUES (56201, 1)";
    $db->query($sql);
    
    // Crear directorio para el servicio Node.js
    $nodejs_dir = '/var/www/html/admin/modules/trunkmanager/nodejs';
    if (!file_exists($nodejs_dir)) {
        mkdir($nodejs_dir, 0755, true);
    }
    
    // Copiar archivos de la API Node.js
    $source_files = [
        'app.js' => $nodejs_dir . '/app.js',
        'package.json' => $nodejs_dir . '/package.json'
    ];
    
    foreach ($source_files as $source => $dest) {
        if (file_exists($source)) {
            copy($source, $dest);
        }
    }
    
    // Copiar directorio examples
    $examples_source = 'examples';
    $examples_dest = $nodejs_dir . '/examples';
    if (is_dir($examples_source)) {
        if (!is_dir($examples_dest)) {
            mkdir($examples_dest, 0755, true);
        }
        trunkmanager_copy_directory($examples_source, $examples_dest);
    }
    
    // Instalar dependencias de Node.js
    $install_cmd = "cd $nodejs_dir && npm install";
    exec($install_cmd, $output, $return_code);
    
    // Crear archivo de servicio systemd
    $service_content = "[Unit]
Description=Trunk Manager API Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node $nodejs_dir/app.js
WorkingDirectory=$nodejs_dir
Restart=always
RestartSec=10
User=www-data
Group=www-data
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target";

    file_put_contents('/etc/systemd/system/trunkmanager-api.service', $service_content);
    
    // Recargar systemd y habilitar servicio
    exec('systemctl daemon-reload');
    exec('systemctl enable trunkmanager-api');
    exec('systemctl start trunkmanager-api');
    
    // Crear directorio de configuración de trunks si no existe
    $trunks_dir = '/etc/asterisk/trunks';
    if (!is_dir($trunks_dir)) {
        mkdir($trunks_dir, 0755, true);
    }
    
    return true;
}

// Función auxiliar para copiar directorios recursivamente
function trunkmanager_copy_directory($src, $dst) {
    $dir = opendir($src);
    if (!is_dir($dst)) {
        mkdir($dst, 0755, true);
    }
    
    while (($file = readdir($dir)) !== false) {
        if ($file != '.' && $file != '..') {
            if (is_dir($src . '/' . $file)) {
                trunkmanager_copy_directory($src . '/' . $file, $dst . '/' . $file);
            } else {
                copy($src . '/' . $file, $dst . '/' . $file);
            }
        }
    }
    closedir($dir);
}

// Ejecutar instalación
if (trunkmanager_install()) {
    echo "Trunk Manager instalado correctamente\n";
} else {
    echo "Error durante la instalación de Trunk Manager\n";
}
?>
