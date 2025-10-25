<?php
/**
 * Trunk Manager Module - Archivo de configuración adicional
 */

// Verificar autenticación de FreePBX
if (!defined('FREEPBX_IS_AUTH')) {
    die('Not for direct access');
}

// Configuración del módulo
$module_conf = [
    'module_name' => 'trunkmanager',
    'version' => '1.0.0',
    'api_port' => 56201,
    'api_enabled' => true,
    'trunks_directory' => '/etc/asterisk/trunks',
    'service_name' => 'trunkmanager-api',
    'nodejs_path' => '/usr/bin/node',
    'supported_types' => [
        'custom' => 'Custom SIP',
        'twilio' => 'Twilio',
        'plivo' => 'Plivo',
        'signalwire' => 'SignalWire',
        'vonage' => 'Vonage',
        'telnyx' => 'Telnyx'
    ]
];

// Función para verificar dependencias
function checkDependencies() {
    $dependencies = [
        'node' => '/usr/bin/node',
        'npm' => '/usr/bin/npm',
        'systemctl' => '/bin/systemctl',
        'asterisk' => '/usr/sbin/asterisk'
    ];
    
    $missing = [];
    foreach ($dependencies as $name => $path) {
        if (!file_exists($path)) {
            $missing[] = $name;
        }
    }
    
    return $missing;
}

// Función para verificar permisos
function checkPermissions() {
    $paths = [
        '/etc/asterisk/trunks' => 'rw',
        '/var/www/html/admin/modules/trunkmanager' => 'rw',
        '/etc/systemd/system' => 'w'
    ];
    
    $issues = [];
    foreach ($paths as $path => $required) {
        if (!is_dir($path)) {
            $issues[] = "Directorio no existe: $path";
            continue;
        }
        
        if ($required === 'rw' && (!is_readable($path) || !is_writable($path))) {
            $issues[] = "Sin permisos de lectura/escritura: $path";
        } elseif ($required === 'w' && !is_writable($path)) {
            $issues[] = "Sin permisos de escritura: $path";
        }
    }
    
    return $issues;
}

// Función para obtener estado del servicio
function getServiceStatus() {
    $status = shell_exec('systemctl is-active trunkmanager-api 2>/dev/null');
    $enabled = shell_exec('systemctl is-enabled trunkmanager-api 2>/dev/null');
    
    return [
        'active' => trim($status) === 'active',
        'enabled' => trim($enabled) === 'enabled',
        'status_text' => trim($status),
        'enabled_text' => trim($enabled)
    ];
}

// Función para reiniciar el servicio
function restartService() {
    exec('systemctl restart trunkmanager-api', $output, $return_code);
    return $return_code === 0;
}

// Función para obtener logs del servicio
function getServiceLogs($lines = 50) {
    $logs = shell_exec("journalctl -u trunkmanager-api --no-pager -n $lines 2>/dev/null");
    return $logs ?: 'No hay logs disponibles';
}

// Función para verificar conectividad de la API
function checkAPIConnectivity() {
    $config = getTrunkManagerConfig();
    $url = "http://localhost:" . $config['api_port'] . "/health";
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 5);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 5);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return [
        'connected' => $httpCode === 200,
        'http_code' => $httpCode,
        'response' => $response
    ];
}

// Función para obtener configuración (reutilizada de config.php)
function getTrunkManagerConfig() {
    global $db;
    $sql = "SELECT * FROM trunkmanager_config ORDER BY id DESC LIMIT 1";
    $result = $db->getRow($sql);
    return $result ?: ['api_port' => 56201, 'api_enabled' => 1];
}

// Función para crear endpoint de salud en la API Node.js
function createHealthEndpoint() {
    $nodejs_dir = '/var/www/html/admin/modules/trunkmanager/nodejs';
    $health_endpoint = "
// Endpoint de salud para verificación
app.get('/health', (req, res) => {
    res.json({ 
        status: 'ok', 
        timestamp: new Date().toISOString(),
        port: PORT 
    });
});
";
    
    $app_file = $nodejs_dir . '/app.js';
    if (file_exists($app_file)) {
        $content = file_get_contents($app_file);
        if (strpos($content, '/health') === false) {
            $content = str_replace('app.listen(PORT, () => {', $health_endpoint . "\napp.listen(PORT, () => {", $content);
            file_put_contents($app_file, $content);
        }
    }
}

// Función para configurar firewall (opcional)
function configureFirewall() {
    $commands = [
        'firewall-cmd --permanent --add-port=56201/tcp',
        'firewall-cmd --reload'
    ];
    
    foreach ($commands as $cmd) {
        exec($cmd, $output, $return_code);
        if ($return_code !== 0) {
            return false;
        }
    }
    
    return true;
}

// Función para crear backup de configuración
function createBackup() {
    $backup_dir = '/var/backups/trunkmanager';
    if (!is_dir($backup_dir)) {
        mkdir($backup_dir, 0755, true);
    }
    
    $timestamp = date('Y-m-d_H-i-s');
    $backup_file = $backup_dir . '/trunkmanager_' . $timestamp . '.tar.gz';
    
    $trunks_dir = '/etc/asterisk/trunks';
    $cmd = "tar -czf $backup_file $trunks_dir/Trunk_*.conf 2>/dev/null";
    
    exec($cmd, $output, $return_code);
    return $return_code === 0 ? $backup_file : false;
}

// Función para restaurar backup
function restoreBackup($backup_file) {
    if (!file_exists($backup_file)) {
        return false;
    }
    
    $cmd = "tar -xzf $backup_file -C /";
    exec($cmd, $output, $return_code);
    
    if ($return_code === 0) {
        exec("asterisk -rx 'pjsip reload'");
        return true;
    }
    
    return false;
}

// Función para validar configuración de trunk
function validateTrunkConfig($config) {
    $required_fields = ['username', 'password', 'server'];
    
    foreach ($required_fields as $field) {
        if (empty($config[$field])) {
            return "Campo requerido faltante: $field";
        }
    }
    
    // Validar formato de servidor
    if (!filter_var($config['server'], FILTER_VALIDATE_DOMAIN) && 
        !filter_var($config['server'], FILTER_VALIDATE_IP)) {
        return "Formato de servidor no válido";
    }
    
    return true;
}

?>
