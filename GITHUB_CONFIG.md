# Configuración del Repositorio GitHub

## Información del Proyecto

**Nombre:** Trunk Manager Module  
**Descripción:** Módulo profesional para FreePBX que permite la gestión automática de trunks SIP mediante API REST  
**URL:** https://github.com/UnCarnaval/addtrunkapi-module  
**Licencia:** GPL v3  
**Lenguaje principal:** JavaScript (Node.js) + PHP  

## Temas (Topics)

- freepbx
- asterisk
- sip
- voip
- trunk-management
- api-rest
- nodejs
- php
- telecommunications
- pbx

## Configuración Recomendada

### Branch Protection Rules
- **main/master:** Requerir PR para cambios
- **Require status checks:** CI/CD debe pasar
- **Require reviews:** Al menos 1 review
- **Restrict pushes:** Solo admins pueden push directo

### Issues y PRs
- **Templates:** Usar templates para Issues y PRs
- **Labels:** bug, enhancement, documentation, question
- **Milestones:** v1.0.0, v1.1.0, etc.

### Releases
- **Tag format:** v1.0.0, v1.1.0
- **Release notes:** Automáticas desde commits
- **Assets:** trunkmanager-1.0.0.tgz

## Archivos de Configuración

### .github/ISSUE_TEMPLATE/bug_report.md
```markdown
---
name: Bug report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Environment:**
- FreePBX Version: [e.g. 13.0.190.64]
- Node.js Version: [e.g. 16.14.0]
- Asterisk Version: [e.g. 18.5.0]

**Additional context**
Add any other context about the problem here.
```

### .github/ISSUE_TEMPLATE/feature_request.md
```markdown
---
name: Feature request
about: Suggest an idea for this project
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

**Is your feature request related to a problem? Please describe.**
A clear and concise description of what the problem is. Ex. I'm always frustrated when [...]

**Describe the solution you'd like**
A clear and concise description of what you want to happen.

**Describe alternatives you've considered**
A clear and concise description of any alternative solutions or features you've considered.

**Additional context**
Add any other context or screenshots about the feature request here.
```

### .github/PULL_REQUEST_TEMPLATE.md
```markdown
## Descripción
Breve descripción de los cambios realizados.

## Tipo de cambio
- [ ] Bug fix (cambio que corrige un problema)
- [ ] Nueva funcionalidad (cambio que agrega funcionalidad)
- [ ] Breaking change (cambio que causa que la funcionalidad existente no funcione como se esperaba)
- [ ] Documentación (cambio solo en documentación)

## Checklist
- [ ] Mi código sigue las convenciones de estilo del proyecto
- [ ] He realizado una auto-revisión de mi código
- [ ] He comentado mi código, especialmente en áreas difíciles de entender
- [ ] He realizado los cambios correspondientes en la documentación
- [ ] Mis cambios no generan nuevas advertencias
- [ ] He agregado pruebas que prueban que mi corrección es efectiva o que mi funcionalidad funciona
- [ ] Las pruebas nuevas y existentes pasan localmente con mis cambios
- [ ] Cualquier cambio dependiente ha sido fusionado y publicado

## Testing
Describe las pruebas que realizaste para verificar tus cambios.

## Screenshots (si aplica)
Agrega screenshots para ayudar a explicar tus cambios.

## Información adicional
Cualquier información adicional que consideres relevante.
```

## Configuración de GitHub Pages

### Para documentación:
- **Source:** Deploy from a branch
- **Branch:** gh-pages
- **Folder:** / (root)

### Archivos de documentación:
- README.md (página principal)
- docs/ (documentación adicional)
- API_EXAMPLES.md
- CONFIG.md
- INSTALL_GUIDE.md

## Configuración de Actions

### Workflows incluidos:
- **CI/CD:** Build y test automático
- **Release:** Crear releases automáticamente
- **Security:** Escaneo de vulnerabilidades

### Secrets requeridos:
- `NPM_TOKEN` (para publicar paquetes)
- `DEPLOY_KEY` (para deployment)

## Configuración de Dependabot

### Archivos a monitorear:
- package.json
- package-lock.json
- .github/workflows/*.yml

### Configuración:
- **Update schedule:** Weekly
- **Open pull requests limit:** 5
- **Target branch:** main

## Configuración de Code Scanning

### Herramientas recomendadas:
- **CodeQL:** Análisis estático de código
- **Dependabot:** Alertas de seguridad
- **Codecov:** Cobertura de código

## Configuración de Discussions

### Categorías:
- **General:** Discusiones generales
- **Q&A:** Preguntas y respuestas
- **Ideas:** Ideas para nuevas funcionalidades
- **Show and tell:** Mostrar implementaciones

## Configuración de Wiki

### Páginas recomendadas:
- **Home:** Página principal
- **Installation:** Guía de instalación
- **Configuration:** Configuración avanzada
- **API Reference:** Referencia de la API
- **Troubleshooting:** Solución de problemas
- **Contributing:** Guía para contribuir

## Configuración de Security

### Configuración recomendada:
- **Dependabot alerts:** Habilitado
- **Dependabot security updates:** Habilitado
- **Code scanning:** Habilitado
- **Secret scanning:** Habilitado
- **Push protection:** Habilitado

## Configuración de Notifications

### Configuración recomendada:
- **Issues:** Notificar a participantes
- **Pull requests:** Notificar a participantes
- **Releases:** Notificar a watchers
- **Discussions:** Notificar a participantes
