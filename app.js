const express = require('express');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const randString = require("randomstring");
const app = express();
const PORT = 56201;

app.use(express.json());

const PJSIP_DIR = "/etc/asterisk/trunks/";

// Función para detectar automáticamente el tipo de proveedor basándose en el servidor
const detectProviderType = (server) => {
    const serverLower = server.toLowerCase();
    
    // Mapeo de dominios conocidos a tipos de proveedor
    const providerMappings = {
        'twilio': ['twilio.com', 'sip.twilio.com'],
        'plivo': ['plivo.com', 'sip.plivo.com'],
        'signalwire': ['signalwire.com', 'sip.signalwire.com'],
        'telnyx': ['telnyx.com', 'sip.telnyx.com'],
        'vonage': ['vonage.com', 'sip.vonage.com', 'nexmo.com']
    };
    
    // Buscar coincidencias en los dominios
    for (const [provider, domains] of Object.entries(providerMappings)) {
        for (const domain of domains) {
            if (serverLower.includes(domain)) {
                return provider;
            }
        }
    }
    
    // Si no se encuentra coincidencia, usar custom
    return 'custom';
};

const getConfig = (file) => fs.readFileSync(file,'utf-8');

const changeVars = (template, variables) => {
    return template.replace(/\${(.*?)}/g, (match, p1) => {
        return variables[p1] !== undefined ? variables[p1] : '';
    });
}


app.post('/add-trunk', (req, res) => {
    const { username, password, server } = req.body;

    // Detectar automáticamente el tipo de proveedor
    const type = detectProviderType(server);

    const trunkName = `_${randString.generate(5)}`;
    if (!trunkName || !username || !password || !server) {
        return res.status(200).json({ error: "Missing parameters. Required: username, password, server" });
    }

    const filePath = `${PJSIP_DIR}${trunkName}.conf`;

    const trunkConfig = path.join(__dirname, "examples", `${type}.conf`);

    if(!fs.existsSync(trunkConfig)) {
        return res.status(200).json({ error: "Configuration not found." });
    }

    const trunkSample = getConfig(trunkConfig);
    const trunkComplete = changeVars(trunkSample, {name:trunkName, username, password, server});

    fs.writeFile(filePath, trunkComplete, (err) => {
        if (err) {
            console.log(err);
            return res.status(200).json({ error: "Error al escribir el archivo." });
        }


        const commands = [
            "asterisk -rx 'module reload res_pjsip.so'",
            "asterisk -rx 'module reload res_pjsip_registrar.so'",
            "asterisk -rx 'module reload res_pjsip_outbound_registration.so'",
            "asterisk -rx 'module reload res_pjsip_endpoint_identifier_ip.so'",
            "asterisk -rx 'pjsip reload'"
        ];
        const executeCommands = (index) => {
            if (index >= commands.length) {
                return res.json({ 
                    message: `Trunk ${trunkName} agregado y recargado correctamente.`,
                    trunk: `${type}${trunkName}`,
                    detected_provider: type,
                    server: server
                });
            }
    
            exec(commands[index], (error, stdout, stderr) => {
                if (error) {
                    return res.status(200).json({ error: `Error al ejecutar: ${commands[index]}` });
                }
                executeCommands(index + 1);
            });
        };
    
        executeCommands(0);
    });
});

// Endpoint para obtener información sobre detección de proveedores
app.get('/detect-provider/:server', (req, res) => {
    const { server } = req.params;
    const detectedType = detectProviderType(server);
    
    res.json({
        server: server,
        detected_provider: detectedType,
        message: `Proveedor detectado: ${detectedType}`
    });
});

// Endpoint de salud para verificación
app.get('/health', (req, res) => {
    res.json({ 
        status: 'ok', 
        timestamp: new Date().toISOString(),
        port: PORT,
        auto_detection: true,
        supported_providers: ['twilio', 'plivo', 'signalwire', 'telnyx', 'vonage', 'custom']
    });
});

app.delete('/delete-trunk/:trunkName', (req, res) => {
    const { trunkName } = req.params;
    
    // Verificar que el nombre del trunk incluya el proveedor (formato: proveedor_nombre)
    if (!trunkName.includes('_')) {
        return res.status(200).json({ 
            error: "Debe proporcionar el nombre completo del trunk (formato: proveedor_nombre). Ejemplo: telnyx_ABC123" 
        });
    }
    
    // Extraer solo la parte del nombre del archivo (después del proveedor_)
    const fileName = trunkName.split('_').slice(1).join('_'); // En caso de múltiples guiones bajos
    const filePath = `${PJSIP_DIR}${fileName}.conf`;

    if (!fs.existsSync(filePath)) {
        return res.status(200).json({ error: "El trunk no existe." });
    }

    fs.unlink(filePath, (err) => {
        if (err) return res.status(200).json({ error: "Error al eliminar el archivo." });

        exec("asterisk -rx 'pjsip reload'", (error, stdout, stderr) => {
            if (error) return res.status(200).json({ error: "Error al recargar Asterisk." });
            res.json({ message: `Trunk ${trunkName} eliminado y configuración recargada.` });
        });
    });
});

app.listen(PORT, () => {
    console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
});
