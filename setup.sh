#!/bin/bash

sudo apt-get update
sudo apt-get install -y python3-pip
sudo apt-get install libpq-dev
sudo apt-get install -y postgresql-client
sudo apt-get install -y git
pip3 install psycopg2-binary
pip3 install Flask 
git clone https://github.com/CristianLatnok/files-py-json.git
cd files-py-json
python insert.py
echo "Instalación y configuración completadas. Puedes acceder a la aplicación usando postman metodo POST en http://35.193.67.243:5000/insertar_usuario y http://35.193.67.243:5000/consulta"
