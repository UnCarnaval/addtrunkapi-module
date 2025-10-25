<?php
/**
 * Trunk Manager - Interfaz principal de configuración
 */

// Verificar autenticación de FreePBX
if (!defined('FREEPBX_IS_AUTH')) {
    die('Not for direct access');
}

// Incluir framework de FreePBX
$request = $_REQUEST;
$request['view'] = !empty($request['view']) ? $request['view'] : 'main';
$request['action'] = !empty($request['action']) ? $request['action'] : '';

// Función para obtener configuración actual
function getTrunkManagerConfig() {
    global $db;
    $sql = "SELECT * FROM trunkmanager_config ORDER BY id DESC LIMIT 1";
    $result = $db->getRow($sql);
    return $result ?: ['api_port' => 56201, 'api_enabled' => 1];
}

// Función para guardar configuración
function saveTrunkManagerConfig($data) {
    global $db;
    $sql = "UPDATE trunkmanager_config SET api_port = ?, api_enabled = ? WHERE id = 1";
    return $db->query($sql, [$data['api_port'], $data['api_enabled']]);
}

// Función para hacer llamadas a la API
function callTrunkManagerAPI($endpoint, $method = 'GET', $data = null) {
    $config = getTrunkManagerConfig();
    $url = "http://localhost:" . $config['api_port'] . $endpoint;
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    
    if ($method === 'POST') {
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    } elseif ($method === 'DELETE') {
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'DELETE');
    }
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return ['code' => $httpCode, 'data' => json_decode($response, true)];
}

// Procesar acciones
if ($request['action'] === 'save_config') {
    $result = saveTrunkManagerConfig($request);
    if ($result) {
        $message = "Configuración guardada correctamente";
        $messageType = "success";
    } else {
        $message = "Error al guardar la configuración";
        $messageType = "error";
    }
} elseif ($request['action'] === 'add_trunk') {
    $apiResponse = callTrunkManagerAPI('/add-trunk', 'POST', [
        'username' => $request['username'],
        'password' => $request['password'],
        'server' => $request['server']
    ]);
    
    if ($apiResponse['code'] === 200 && !isset($apiResponse['data']['error'])) {
        $detectedProvider = $apiResponse['data']['detected_provider'] ?? 'unknown';
        $message = "Trunk agregado correctamente: " . $apiResponse['data']['trunk'] . " (Proveedor detectado: " . $detectedProvider . ")";
        $messageType = "success";
    } else {
        $message = "Error al agregar trunk: " . ($apiResponse['data']['error'] ?? 'Error desconocido');
        $messageType = "error";
    }
} elseif ($request['action'] === 'delete_trunk') {
    $apiResponse = callTrunkManagerAPI('/delete-trunk/' . $request['trunk_name'], 'DELETE');
    
    if ($apiResponse['code'] === 200 && !isset($apiResponse['data']['error'])) {
        $message = "Trunk eliminado correctamente";
        $messageType = "success";
    } else {
        $message = "Error al eliminar trunk: " . ($apiResponse['data']['error'] ?? 'Error desconocido');
        $messageType = "error";
    }
}

// Obtener configuración actual
$config = getTrunkManagerConfig();

// Obtener lista de trunks existentes
$trunks_dir = '/etc/asterisk/trunks';
$existing_trunks = [];
if (is_dir($trunks_dir)) {
    $files = glob($trunks_dir . '/Trunk_*.conf');
    foreach ($files as $file) {
        $filename = basename($file, '.conf');
        $existing_trunks[] = $filename;
    }
}

?>
<div class="container-fluid">
    <div class="row">
        <div class="col-sm-12">
            <div class="fpbx-container">
                <div class="display no-border">
                    <div class="nav-container">
                        <div class="nav nav-tabs" role="tablist">
                            <a class="nav-item nav-link active" data-toggle="tab" href="#config" role="tab">Configuración</a>
                            <a class="nav-item nav-link" data-toggle="tab" href="#trunks" role="tab">Gestión de Trunks</a>
                            <a class="nav-item nav-link" data-toggle="tab" href="#logs" role="tab">Logs</a>
                        </div>
                    </div>
                    <div class="tab-content">
                        <!-- Pestaña de Configuración -->
                        <div class="tab-pane active" id="config" role="tabpanel">
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="panel panel-primary">
                                        <div class="panel-heading">
                                            <h3 class="panel-title">Configuración del Servicio API</h3>
                                        </div>
                                        <div class="panel-body">
                                            <form method="post" action="">
                                                <input type="hidden" name="action" value="save_config">
                                                <div class="form-group">
                                                    <label for="api_port">Puerto de la API:</label>
                                                    <input type="number" class="form-control" id="api_port" name="api_port" 
                                                           value="<?php echo htmlspecialchars($config['api_port']); ?>" min="1024" max="65535">
                                                </div>
                                                <div class="form-group">
                                                    <label>
                                                        <input type="checkbox" name="api_enabled" value="1" 
                                                               <?php echo $config['api_enabled'] ? 'checked' : ''; ?>> 
                                                        Habilitar API
                                                    </label>
                                                </div>
                                                <button type="submit" class="btn btn-primary">Guardar Configuración</button>
                                            </form>
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="panel panel-info">
                                        <div class="panel-heading">
                                            <h3 class="panel-title">Estado del Servicio</h3>
                                        </div>
                                        <div class="panel-body">
                                            <?php
                                            $service_status = shell_exec('systemctl is-active trunkmanager-api 2>/dev/null');
                                            $status_class = trim($service_status) === 'active' ? 'success' : 'danger';
                                            $status_text = trim($service_status) === 'active' ? 'Activo' : 'Inactivo';
                                            ?>
                                            <p><strong>Estado:</strong> <span class="label label-<?php echo $status_class; ?>"><?php echo $status_text; ?></span></p>
                                            <p><strong>Puerto:</strong> <?php echo $config['api_port']; ?></p>
                                            <p><strong>URL API:</strong> http://localhost:<?php echo $config['api_port']; ?></p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Pestaña de Gestión de Trunks -->
                        <div class="tab-pane" id="trunks" role="tabpanel">
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="panel panel-success">
                                        <div class="panel-heading">
                                            <h3 class="panel-title">Agregar Nuevo Trunk</h3>
                                        </div>
                                        <div class="panel-body">
                                            <form method="post" action="">
                                                <input type="hidden" name="action" value="add_trunk">
                                                <div class="form-group">
                                                    <label for="username">Usuario:</label>
                                                    <input type="text" class="form-control" id="username" name="username" required>
                                                </div>
                                                <div class="form-group">
                                                    <label for="password">Contraseña:</label>
                                                    <input type="password" class="form-control" id="password" name="password" required>
                                                </div>
                                                <div class="form-group">
                                                    <label for="server">Servidor:</label>
                                                    <input type="text" class="form-control" id="server" name="server" required 
                                                           placeholder="sip.ejemplo.com">
                                                    <small class="form-text text-muted">
                                                        El tipo de proveedor se detectará automáticamente basándose en el servidor.
                                                        Soporta: Twilio, Plivo, SignalWire, Telnyx, Vonage y Custom.
                                                    </small>
                                                </div>
                                                <button type="submit" class="btn btn-success">Agregar Trunk</button>
                                            </form>
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="panel panel-warning">
                                        <div class="panel-heading">
                                            <h3 class="panel-title">Trunks Existentes</h3>
                                        </div>
                                        <div class="panel-body">
                                            <?php if (empty($existing_trunks)): ?>
                                                <p>No hay trunks configurados.</p>
                                            <?php else: ?>
                                                <div class="table-responsive">
                                                    <table class="table table-striped">
                                                        <thead>
                                                            <tr>
                                                                <th>Nombre</th>
                                                                <th>Acciones</th>
                                                            </tr>
                                                        </thead>
                                                        <tbody>
                                                            <?php foreach ($existing_trunks as $trunk): ?>
                                                                <tr>
                                                                    <td><?php echo htmlspecialchars($trunk); ?></td>
                                                                    <td>
                                                                        <form method="post" action="" style="display: inline;">
                                                                            <input type="hidden" name="action" value="delete_trunk">
                                                                            <input type="hidden" name="trunk_name" value="<?php echo htmlspecialchars($trunk); ?>">
                                                                            <button type="submit" class="btn btn-danger btn-sm" 
                                                                                    onclick="return confirm('¿Estás seguro de eliminar este trunk?')">
                                                                                Eliminar
                                                                            </button>
                                                                        </form>
                                                                    </td>
                                                                </tr>
                                                            <?php endforeach; ?>
                                                        </tbody>
                                                    </table>
                                                </div>
                                            <?php endif; ?>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Pestaña de Logs -->
                        <div class="tab-pane" id="logs" role="tabpanel">
                            <div class="panel panel-default">
                                <div class="panel-heading">
                                    <h3 class="panel-title">Logs del Servicio</h3>
                                </div>
                                <div class="panel-body">
                                    <pre style="max-height: 400px; overflow-y: auto;"><?php
                                        $logs = shell_exec('journalctl -u trunkmanager-api --no-pager -n 50 2>/dev/null');
                                        echo htmlspecialchars($logs ?: 'No hay logs disponibles');
                                    ?></pre>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<?php if (isset($message)): ?>
<script>
$(document).ready(function() {
    var alertClass = '<?php echo $messageType === 'success' ? 'alert-success' : 'alert-danger'; ?>';
    var alertHtml = '<div class="alert ' + alertClass + ' alert-dismissible fade in" role="alert">' +
                    '<button type="button" class="close" data-dismiss="alert" aria-label="Close">' +
                    '<span aria-hidden="true">&times;</span></button>' +
                    '<?php echo htmlspecialchars($message); ?>' +
                    '</div>';
    $('.fpbx-container').prepend(alertHtml);
});
</script>
<?php endif; ?>
