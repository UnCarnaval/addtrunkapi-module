# Trunk Manager Module - FreePBX

## 📋 Descripción

Módulo profesional para FreePBX que permite la gestión automática de trunks SIP mediante API REST. Incluye detección automática de proveedores y interfaz web integrada.

## ✨ Características Principales

- 🎯 **Detección automática de proveedores** - Solo necesitas usuario, contraseña y servidor
- 🌐 **API REST completa** - Para integración con otros sistemas
- 🖥️ **Interfaz web integrada** - Accesible desde FreePBX Admin
- 🔧 **Instalación automática** - Como servicio systemd
- 📊 **Múltiples proveedores** - Twilio, Plivo, SignalWire, Telnyx, Vonage, Custom
- 🔒 **Seguridad integrada** - Validaciones y logging de actividad
- 📦 **Instalación remota** - Sin acceso físico al servidor

## 🚀 Instalación Rápida

### Para Sangoma 7 / CentOS 7 (Recomendado)

```bash
# Instalación en 3 comandos
wget https://raw.githubusercontent.com/UnCarnaval/addtrunkapi-module/main/install-sangoma7.sh
chmod +x install-sangoma7.sh
sudo ./install-sangoma7.sh
```

### Instalación Completa (Limpieza + Instalación)

```bash
# Si tienes problemas o instalación anterior
wget https://raw.githubusercontent.com/UnCarnaval/addtrunkapi-module/main/install-complete.sh
chmod +x install-complete.sh
sudo ./install-complete.sh
```
```

### Opción 3: Desde GitHub
```bash
# Clonar repositorio
git clone https://github.com/UnCarnaval/addtrunkapi-module.git
cd addtrunkapi-module

# Crear paquete e instalar
./create-package.sh
```

## 📖 Documentación

- **[README.md](README.md)** - Documentación completa
- **[API_EXAMPLES.md](API_EXAMPLES.md)** - Ejemplos de uso de la API
- **[CONFIG.md](CONFIG.md)** - Configuración avanzada
- **[INSTALL_GUIDE.md](INSTALL_GUIDE.md)** - Guía de instalación
- **[INSTALL_REMOTE.md](INSTALL_REMOTE.md)** - Instalación remota

## 🔧 Uso de la API

### Agregar Trunk (Detección Automática)
```bash
curl -X POST http://localhost:56201/add-trunk \
  -H "Content-Type: application/json" \
  -d '{
    "username": "tu_usuario",
    "password": "tu_contraseña",
    "server": "sip.telnyx.com"
  }'
```

### Detectar Proveedor
```bash
curl http://localhost:56201/detect-provider/sip.telnyx.com
```

## 🎯 Proveedores Soportados

| Proveedor | Dominios Detectados | Configuración |
|-----------|-------------------|---------------|
| **Twilio** | twilio.com, sip.twilio.com | ✅ Optimizada |
| **Plivo** | plivo.com, sip.plivo.com | ✅ Optimizada |
| **SignalWire** | signalwire.com, sip.signalwire.com | ✅ Optimizada |
| **Telnyx** | telnyx.com, sip.telnyx.com | ✅ Optimizada |
| **Vonage** | vonage.com, sip.vonage.com | ✅ Optimizada |
| **Custom** | Cualquier otro dominio | ✅ Genérica |

## 📋 Requisitos

- FreePBX 13.0.0 o superior
- Node.js 12.x o superior
- Asterisk con módulos PJSIP
- Permisos de administrador en FreePBX

## 🛠️ Desarrollo

### Estructura del Proyecto
```
trunkmanager/
├── module.xml              # Metadatos del módulo
├── install.php             # Script de instalación
├── uninstall.php           # Script de desinstalación
├── config.php              # Interfaz web principal
├── app.js                  # API Node.js
├── package.json            # Dependencias Node.js
├── examples/               # Plantillas de configuración
│   ├── custom.conf
│   ├── twilio.conf
│   ├── plivo.conf
│   ├── signalwire.conf
│   ├── telnyx.conf
│   └── vonage.conf
└── scripts/                # Scripts de instalación
    ├── install.sh
    ├── install-remote.sh
    └── create-package.sh
```

### Scripts Disponibles
- `install.sh` - Instalación local
- `install-remote.sh` - Instalación remota via SSH
- `create-package.sh` - Crear paquete .tgz
- `uninstall.sh` - Desinstalación completa

## 🤝 Contribuir

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crea un Pull Request

## 📄 Licencia

Este proyecto está licenciado bajo GPL v3 - ver [LICENSE](LICENSE) para más detalles.

## 🆘 Soporte

- **Issues:** [GitHub Issues](https://github.com/UnCarnaval/addtrunkapi-module/issues)
- **Documentación:** [Wiki del Proyecto](https://github.com/UnCarnaval/addtrunkapi-module/wiki)
- **Email:** soporte@tudominio.com

## 📊 Estado del Proyecto

![CI](https://github.com/UnCarnaval/addtrunkapi-module/workflows/Build%20and%20Test%20Trunk%20Manager%20Module/badge.svg)
![License](https://img.shields.io/badge/license-GPL%20v3-blue.svg)
![Node](https://img.shields.io/badge/node-%3E%3D12.x-green.svg)
![FreePBX](https://img.shields.io/badge/FreePBX-%3E%3D13.0.0-orange.svg)

## 🎉 Changelog

### v1.0.0
- ✅ Lanzamiento inicial
- ✅ Detección automática de proveedores
- ✅ API REST completa
- ✅ Interfaz web integrada
- ✅ Instalación automática como servicio
- ✅ Soporte para múltiples proveedores SIP
- ✅ Scripts de instalación remota
- ✅ Documentación completa
