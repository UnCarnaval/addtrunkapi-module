<?php
/**
 * Trunk Manager Module - Configuración de permisos y seguridad
 */

// Verificar autenticación de FreePBX
if (!defined('FREEPBX_IS_AUTH')) {
    die('Not for direct access');
}

// Configuración de seguridad
$security_config = [
    'allowed_ips' => [
        '127.0.0.1',
        '::1',
        'localhost'
    ],
    'api_timeout' => 30,
    'max_trunks_per_user' => 50,
    'log_api_calls' => true,
    'require_authentication' => true
];

// Función para validar IP
function validateIP($ip) {
    global $security_config;
    return in_array($ip, $security_config['allowed_ips']);
}

// Función para registrar actividad
function logActivity($action, $details = '') {
    global $security_config;
    
    if (!$security_config['log_api_calls']) {
        return;
    }
    
    $log_entry = [
        'timestamp' => date('Y-m-d H:i:s'),
        'action' => $action,
        'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
        'user' => $_SESSION['AMPUSER'] ?? 'unknown',
        'details' => $details
    ];
    
    $log_file = '/var/log/trunkmanager.log';
    file_put_contents($log_file, json_encode($log_entry) . "\n", FILE_APPEND | LOCK_EX);
}

// Función para verificar límites de trunks
function checkTrunkLimits($user_id) {
    global $security_config, $db;
    
    $sql = "SELECT COUNT(*) as count FROM trunkmanager_trunks WHERE user_id = ?";
    $result = $db->getRow($sql, [$user_id]);
    
    return $result['count'] < $security_config['max_trunks_per_user'];
}

// Función para sanitizar entrada
function sanitizeInput($input) {
    return htmlspecialchars(strip_tags(trim($input)), ENT_QUOTES, 'UTF-8');
}

// Función para validar configuración de trunk
function validateTrunkConfig($config) {
    $required_fields = ['username', 'password', 'server', 'type'];
    $valid_types = ['custom', 'twilio', 'plivo', 'signalwire', 'vonage'];
    
    foreach ($required_fields as $field) {
        if (empty($config[$field])) {
            return "Campo requerido faltante: $field";
        }
    }
    
    if (!in_array($config['type'], $valid_types)) {
        return "Tipo de trunk no válido";
    }
    
    // Validar formato de servidor
    if (!filter_var($config['server'], FILTER_VALIDATE_DOMAIN) && 
        !filter_var($config['server'], FILTER_VALIDATE_IP)) {
        return "Formato de servidor no válido";
    }
    
    return true;
}

// Función para crear tabla de logs si no existe
function createLogTable() {
    global $db;
    
    $sql = "CREATE TABLE IF NOT EXISTS trunkmanager_logs (
        id INT AUTO_INCREMENT PRIMARY KEY,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        action VARCHAR(100) NOT NULL,
        ip_address VARCHAR(45),
        user_id VARCHAR(50),
        details TEXT,
        INDEX idx_timestamp (timestamp),
        INDEX idx_action (action)
    )";
    
    return $db->query($sql);
}

// Función para crear tabla de trunks si no existe
function createTrunksTable() {
    global $db;
    
    $sql = "CREATE TABLE IF NOT EXISTS trunkmanager_trunks (
        id INT AUTO_INCREMENT PRIMARY KEY,
        trunk_name VARCHAR(100) NOT NULL,
        username VARCHAR(100) NOT NULL,
        server VARCHAR(255) NOT NULL,
        type VARCHAR(50) NOT NULL,
        user_id VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY unique_trunk_name (trunk_name),
        INDEX idx_user_id (user_id),
        INDEX idx_type (type)
    )";
    
    return $db->query($sql);
}

// Función para obtener estadísticas del módulo
function getModuleStats() {
    global $db;
    
    $stats = [];
    
    // Contar trunks por tipo
    $sql = "SELECT type, COUNT(*) as count FROM trunkmanager_trunks GROUP BY type";
    $results = $db->getAll($sql);
    
    foreach ($results as $result) {
        $stats['trunks_by_type'][$result['type']] = $result['count'];
    }
    
    // Contar total de trunks
    $sql = "SELECT COUNT(*) as total FROM trunkmanager_trunks";
    $result = $db->getRow($sql);
    $stats['total_trunks'] = $result['total'];
    
    // Contar usuarios activos
    $sql = "SELECT COUNT(DISTINCT user_id) as users FROM trunkmanager_trunks";
    $result = $db->getRow($sql);
    $stats['active_users'] = $result['users'];
    
    // Obtener actividad reciente
    $sql = "SELECT action, COUNT(*) as count FROM trunkmanager_logs 
            WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR) 
            GROUP BY action";
    $results = $db->getAll($sql);
    
    foreach ($results as $result) {
        $stats['recent_activity'][$result['action']] = $result['count'];
    }
    
    return $stats;
}

// Función para limpiar logs antiguos
function cleanOldLogs($days = 30) {
    global $db;
    
    $sql = "DELETE FROM trunkmanager_logs WHERE timestamp < DATE_SUB(NOW(), INTERVAL ? DAY)";
    $result = $db->query($sql, [$days]);
    
    return $result;
}

// Función para exportar configuración
function exportConfiguration() {
    global $db;
    
    $config = [];
    
    // Obtener configuración del módulo
    $sql = "SELECT * FROM trunkmanager_config ORDER BY id DESC LIMIT 1";
    $config['module_config'] = $db->getRow($sql);
    
    // Obtener trunks
    $sql = "SELECT * FROM trunkmanager_trunks ORDER BY created_at DESC";
    $config['trunks'] = $db->getAll($sql);
    
    // Obtener logs recientes
    $sql = "SELECT * FROM trunkmanager_logs ORDER BY timestamp DESC LIMIT 100";
    $config['recent_logs'] = $db->getAll($sql);
    
    return $config;
}

// Función para importar configuración
function importConfiguration($config_data) {
    global $db;
    
    try {
        $db->beginTransaction();
        
        // Importar configuración del módulo
        if (isset($config_data['module_config'])) {
            $sql = "INSERT INTO trunkmanager_config (api_port, api_enabled) VALUES (?, ?)";
            $db->query($sql, [
                $config_data['module_config']['api_port'],
                $config_data['module_config']['api_enabled']
            ]);
        }
        
        // Importar trunks
        if (isset($config_data['trunks'])) {
            foreach ($config_data['trunks'] as $trunk) {
                $sql = "INSERT INTO trunkmanager_trunks (trunk_name, username, server, type, user_id) 
                        VALUES (?, ?, ?, ?, ?)";
                $db->query($sql, [
                    $trunk['trunk_name'],
                    $trunk['username'],
                    $trunk['server'],
                    $trunk['type'],
                    $trunk['user_id']
                ]);
            }
        }
        
        $db->commit();
        return true;
        
    } catch (Exception $e) {
        $db->rollback();
        return false;
    }
}

// Inicializar tablas si no existen
createLogTable();
createTrunksTable();

?>
