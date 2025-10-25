crear carpeta app

arrastrar archivo app.js a la carpeta creada


arrastrar carpeta examples a la misma /app

en terminal hacer esto:

cd app
npm init -y
npm install express randomstring
sudo mkdir -p /etc/asterisk/trunks/  [ o crearla manualmente no importa]
sudo chown -R $(whoami):$(whoami) /etc/asterisk/trunks/
sudo chmod 755 /etc/asterisk/trunks/


luego de crear y ver que app.js esta corriendo agregar esto en pjsip_custom.conf que 
se encuentra en etc/asterisk/*

este comando:
#include trunks/*.conf

este comando es para leer todas las conf de cada reinicio que se encuentren
en la carpeta trunks