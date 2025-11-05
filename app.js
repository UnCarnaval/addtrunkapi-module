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
    const { username, password, server, trunk } = req.body;

    // Detectar automáticamente el tipo de proveedor
    const type = detectProviderType(server);

    // Si se proporciona un nombre de trunk completo, extraer solo la parte del archivo
    let trunkName;
    let fullTrunkName;
    
    if (trunk) {
        // Si viene como "telnyx_DMseO", extraer "_DMseO"
        if (trunk.includes('_')) {
            trunkName = trunk.split('_').slice(1).join('_');
            fullTrunkName = trunk;
        } else {
            trunkName = trunk;
            fullTrunkName = `${type}_${trunk}`;
        }
    } else {
        // Generar nombre automático si no se proporciona
        const hash = randString.generate(5);
        trunkName = `_${hash}`;
        fullTrunkName = `${type}_${hash}`;
    }

    if (!username || !password || !server) {
        return res.status(200).json({ error: "Missing parameters. Required: username, password, server" });
    }

    const filePath = `${PJSIP_DIR}${trunkName}.conf`;

    const trunkConfig = path.join(__dirname, "examples", `${type}.conf`);

    if(!fs.existsSync(trunkConfig)) {
        return res.status(200).json({ error: "Configuration not found." });
    }

    const trunkSample = getConfig(trunkConfig);
    // Para el template, usar el nombre sin el guión bajo inicial (si existe)
    // El archivo usa trunkName con guión bajo, pero el template necesita el nombre limpio
    const templateName = trunkName.startsWith('_') ? trunkName.substring(1) : trunkName;
    const trunkComplete = changeVars(trunkSample, {name: templateName, username, password, server});

    fs.writeFile(filePath, trunkComplete, (err) => {
        if (err) {
            console.log(err);
            return res.status(200).json({ error: "Error al escribir el archivo." });
        }

        // Establecer permisos correctos: legible por asterisk, modificable por root
        fs.chmodSync(filePath, 0o644);
        // Cambiar propietario a root:asterisk para que asterisk pueda leerlo
        exec(`chown root:asterisk "${filePath}"`, (chownErr) => {
            if (chownErr) {
                console.log("Advertencia: No se pudo cambiar propietario del archivo:", chownErr);
            }
        });

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
                    trunk: fullTrunkName,
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

// Función para obtener información detallada de un canal
const getChannelInfo = (channelName, callback) => {
    exec(`asterisk -rx 'core show channel ${channelName}'`, (error, stdout, stderr) => {
        if (error) {
            return callback(null);
        }
        
        const info = {};
        const lines = stdout.split('\n');
        
        lines.forEach(line => {
            if (line.includes('Duration:')) {
                const durationMatch = line.match(/Duration:\s*(\d+):(\d+):(\d+)/);
                if (durationMatch) {
                    info.duration = {
                        hours: parseInt(durationMatch[1]),
                        minutes: parseInt(durationMatch[2]),
                        seconds: parseInt(durationMatch[3]),
                        formatted: durationMatch[0].replace('Duration:', '').trim()
                    };
                }
            }
            if (line.includes('CallerID:')) {
                const callerMatch = line.match(/CallerID:\s*<?([^>]+)>?/);
                if (callerMatch) {
                    info.callerId = callerMatch[1].trim();
                }
            }
            if (line.includes('Connected line:')) {
                const connectedMatch = line.match(/Connected line:\s*<?([^>]+)>?/);
                if (connectedMatch) {
                    info.connectedTo = connectedMatch[1].trim();
                }
            }
        });
        
        callback(info);
    });
};

// Función para obtener todas las llamadas activas
const getActiveCalls = (callback) => {
    exec("asterisk -rx 'core show channels'", (error, stdout, stderr) => {
        if (error) {
            console.error('Error ejecutando core show channels:', error);
            return callback({ error: "Error al obtener llamadas activas", details: error.message }, null);
        }
        
        if (stderr) {
            console.error('Stderr de asterisk:', stderr);
        }
        
        const lines = stdout.split('\n');
        const calls = [];
        let inChannelsSection = false;
        let headerFound = false;
        let headerIndex = -1;
        
        // Parsear la salida
        lines.forEach((line, index) => {
            const trimmedLine = line.trim();
            
            // Detectar inicio de la sección de canales (buscar el header)
            // El header puede ser "Channel              Location             State   Application(Data)" 
            // o "Channel              Context              Extension   Priority  State      Application         Data"
            if (trimmedLine.includes('Channel') && 
                (trimmedLine.includes('Location') || trimmedLine.includes('Context') || trimmedLine.includes('Extension'))) {
                inChannelsSection = true;
                headerFound = true;
                headerIndex = index;
                return;
            }
            
            // Detectar fin de la sección (línea con "active channels" o "active calls" o "channels")
            if (trimmedLine.toLowerCase().includes('active channel') || 
                trimmedLine.toLowerCase().includes('active call') ||
                (trimmedLine.match(/^\d+\s+active\s+channel/i)) ||
                trimmedLine.toLowerCase().includes('calls processed')) {
                inChannelsSection = false;
                return;
            }
            
            // Si estamos en la sección de canales y hay contenido
            if (inChannelsSection && trimmedLine && 
                !trimmedLine.includes('---') && 
                !trimmedLine.includes('Channel') &&
                trimmedLine.length > 0 &&
                index > headerIndex) {
                
                // Intentar detectar si es una línea de canal válida
                // Los canales suelen empezar con PJSIP/, SIP/, IAX2/, DAHDI/, Local/, etc.
                if (trimmedLine.match(/^(PJSIP|SIP|IAX2|DAHDI|Local|Chan|H323)\//)) {
                    // Parsear línea de canal - formato real: 
                    // "PJSIP/telnyx_5Muyo-0 s@from-pstn:1        Up      Stasis(DrMott,f8459f0b-4b02-47"
                    // o "Channel              Location             State   Application(Data)"
                    
                    // Extraer el canal (primer campo, hasta el primer espacio)
                    // El canal puede ser algo como: PJSIP/telnyx_5Muyo-0
                    const channelMatch = trimmedLine.match(/^([^\s]+)/);
                    if (channelMatch) {
                        const channel = channelMatch[1];
                        
                        // Debug: log si no hay muchas llamadas
                        if (calls.length < 5) {
                            console.log(`Parsing line: "${trimmedLine}"`);
                            console.log(`Channel found: "${channel}"`);
                        }
                        
                        // Extraer el nombre del trunk/endpoint del canal
                        // Ejemplo: PJSIP/telnyx_5Muyo-0 -> telnyx_5Muyo
                        let trunkName = null;
                        if (channel.includes('PJSIP/')) {
                            const match = channel.match(/PJSIP\/([^-\s;]+)/);
                            if (match) {
                                trunkName = match[1];
                            }
                        } else if (channel.includes('SIP/')) {
                            const match = channel.match(/SIP\/([^-\s;]+)/);
                            if (match) {
                                trunkName = match[1];
                            }
                        }
                        
                        // Remover el canal del inicio para parsear el resto
                        let restOfLine = trimmedLine.substring(channel.length).trim();
                        
                        // Debug
                        if (calls.length < 5) {
                            console.log(`Rest of line: "${restOfLine}"`);
                        }
                        
                        // Parsear Location, State y Application
                        // Formato real: "s@from-pstn:1        Up      Stasis(DrMott,f8459f0b-4b02-47"
                        // Usar regex que detecte múltiples espacios o espacios únicos
                        // Primero intentar con múltiples espacios (formato más común)
                        let locationMatch = restOfLine.match(/^(.+?)\s{2,}(\w+)\s{2,}(.+)$/);
                        
                        // Si no funciona, intentar con un solo espacio entre campos
                        if (!locationMatch) {
                            locationMatch = restOfLine.match(/^(.+?)\s+(\w+)\s+(.+)$/);
                        }
                        
                        // Debug
                        if (calls.length < 5 && !locationMatch) {
                            console.log(`No locationMatch found for: "${restOfLine}"`);
                        }
                        
                        // Si aún no funciona, usar split simple
                        let location = '';
                        let state = '';
                        let application = '';
                        let data = '';
                        
                        if (locationMatch) {
                            location = locationMatch[1].trim();
                            state = locationMatch[2].trim();
                            const appData = locationMatch[3].trim();
                            
                            // Separar Application y Data (puede tener paréntesis y más datos)
                            // Ejemplo: "Stasis(DrMott,f8459f0b-4b02-47" o "AppDial2((Outgoing Line))"
                            const appMatch = appData.match(/^(\w+(?:\([^)]*\))*)\s*(.*)$/);
                            if (appMatch) {
                                application = appMatch[1];
                                data = appMatch[2] || '';
                            } else {
                                application = appData;
                            }
                        } else {
                            // Parseo de fallback: split por espacios
                            const parts = restOfLine.split(/\s+/);
                            if (parts.length >= 1) {
                                location = parts[0] || '';
                            }
                            if (parts.length >= 2) {
                                state = parts[1] || '';
                            }
                            if (parts.length >= 3) {
                                application = parts[2] || '';
                                data = parts.slice(3).join(' ') || '';
                            }
                        }
                        
                        // Separar context y extension de location si es formato "context:extension"
                        let context = '';
                        let extension = '';
                        if (location.includes(':')) {
                            const locParts = location.split(':');
                            context = locParts[0] || '';
                            extension = locParts[1] || '';
                        } else {
                            context = location;
                        }
                        
                        calls.push({
                            channel: channel,
                            trunk: trunkName,
                            location: location,
                            context: context,
                            extension: extension,
                            state: state,
                            application: application,
                            data: data
                        });
                    }
                }
            }
        });
        
        callback(null, calls);
    });
};

// Endpoint de debug para ver la salida cruda de Asterisk
app.get('/debug/asterisk-channels', (req, res) => {
    exec("asterisk -rx 'core show channels'", (error, stdout, stderr) => {
        res.json({
            error: error ? error.message : null,
            stderr: stderr || null,
            stdout: stdout || null,
            lines: stdout ? stdout.split('\n') : []
        });
    });
});

// Endpoint para obtener todas las llamadas activas
app.get('/active-calls', (req, res) => {
    getActiveCalls((error, calls) => {
        if (error) {
            return res.status(500).json(error);
        }
        
        // Agrupar por trunk
        const callsByTrunk = {};
        const totalCalls = calls.length;
        
        calls.forEach(call => {
            const trunkKey = call.trunk || 'unknown';
            if (!callsByTrunk[trunkKey]) {
                callsByTrunk[trunkKey] = [];
            }
            callsByTrunk[trunkKey].push(call);
        });
        
        res.json({
            total_calls: totalCalls,
            timestamp: new Date().toISOString(),
            calls: calls,
            calls_by_trunk: callsByTrunk,
            summary: Object.keys(callsByTrunk).map(trunk => ({
                trunk: trunk,
                count: callsByTrunk[trunk].length
            }))
        });
    });
});

// Endpoint para obtener llamadas activas de un trunk específico
app.get('/active-calls/:trunkName', (req, res) => {
    const { trunkName } = req.params;
    
    getActiveCalls((error, calls) => {
        if (error) {
            return res.status(500).json(error);
        }
        
        // Filtrar llamadas por trunk
        // El trunkName puede venir como "telnyx_ABC" o solo "ABC"
        let fileName;
        let fullTrunkName;
        
        if (trunkName.includes('_')) {
            fullTrunkName = trunkName;
            fileName = trunkName.split('_').slice(1).join('_');
        } else {
            // Si no tiene _, buscar el tipo de proveedor
            // Por ahora, buscar en todos los archivos de trunks
            const files = fs.readdirSync(PJSIP_DIR);
            const matchingFile = files.find(f => f.includes(trunkName));
            if (matchingFile) {
                fileName = trunkName;
                // Intentar detectar el tipo desde el contenido del archivo
                const fileContent = fs.readFileSync(PJSIP_DIR + matchingFile, 'utf8');
                const typeMatch = fileContent.match(/\[(\w+)_/);
                if (typeMatch) {
                    fullTrunkName = `${typeMatch[1]}_${trunkName}`;
                } else {
                    fullTrunkName = trunkName;
                }
            } else {
                fullTrunkName = trunkName;
                fileName = trunkName;
            }
        }
        
        // Filtrar llamadas que coincidan con el trunk
        const trunkCalls = calls.filter(call => {
            if (!call.trunk) return false;
            // Comparar con el nombre completo o solo la parte después del _
            return call.trunk === fullTrunkName || 
                   call.trunk === trunkName ||
                   call.trunk.endsWith(`_${fileName}`) ||
                   call.trunk === fileName;
        });
        
        res.json({
            trunk: trunkName,
            full_trunk_name: fullTrunkName,
            total_calls: trunkCalls.length,
            timestamp: new Date().toISOString(),
            calls: trunkCalls
        });
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
    
    // Si viene como "telnyx_DMseO", extraer solo "_DMseO" para el archivo
    let fileName;
    if (trunkName.includes('_')) {
        fileName = trunkName.split('_').slice(1).join('_');
    } else {
        fileName = trunkName;
    }
    
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
