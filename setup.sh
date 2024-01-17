#!/bin/bash

sudo apt-get update
sudo apt-get install -y python-pip
sudo apt-get install -y Flask 
sudo apt-get install -y psycopg2
sudo apt-get install -y postgresql-client
sudo apt-get install -y git
git clone https://github.com/CristianLatnok/files-py-json.git
cd files-py-json
python insert.py
echo "Instalación y configuración completadas. Puedes acceder a la aplicación en http://localhost:80"
