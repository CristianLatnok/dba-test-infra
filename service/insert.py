from flask import Flask, request, jsonify
import psycopg2
import json
import os

app = Flask(__name__)

ruta_archivo_json = os.path.join(os.path.dirname(__file__), 'link-sql.json')

with open(ruta_archivo_json, 'r') as f:
    datos_acceso_db = json.load(f)

db_config = {
    'host': datos_acceso_db['host'],
    'user': datos_acceso_db['user'],
    'password': datos_acceso_db['password'],
    'database': datos_acceso_db['database'],
}

db = psycopg2.connect(**db_config)

@app.route('/crear_tabla', methods=['POST'])
def crear_tabla():
    try:
        
        data = request.get_json()
        consulta_creacion_tabla = data.get(
            'CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, email VARCHAR(255) NOT NULL, password VARCHAR(255) NOT NULL, first_name VARCHAR(255) NOT NULL, last_name VARCHAR(255) NOT NULL, address VARCHAR(255) NOT NULL, postal_code VARCHAR(10) NOT NULL, country VARCHAR(255) NOT NULL);'
            )

        cursor = db.cursor()
        cursor.execute(consulta_creacion_tabla)
        db.commit()

        return jsonify({'mensaje': 'Tabla creada exitosamente'})

    except Exception as e:
        return jsonify({'error: Al crear Tabla User': str(e)})


@app.route('/insertar_usuario', methods=['POST'])
def insertar_usuario():
    try:
        
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        first_name = data.get('first_name')
        last_name = data.get('last_name')
        address = data.get('address')
        postal_code = data.get('postal_code')
        country = data.get('country')

        consulta_insercion = "INSERT INTO users (email, password, first_name, last_name, address, postal_code, country) VALUES ('{0}', '{1}', '{2}', '{3}', '{4}', '{5}', '{6}') RETURNING id;".format(email, password, first_name, last_name, address, postal_code, country)


        cursor = db.cursor()
        cursor.execute(consulta_insercion)
        nuevo_id = cursor.fetchone()[0]
        db.commit()

        return jsonify({'mensaje': f'Usuario insertado exitosamente con ID {nuevo_id}'})

    except Exception as e:
        return jsonify({'error: usuario no registrado': str(e)})


@app.route('/consulta', methods=['POST'])
def ejecutar_consulta():
    try:
        
        data = request.get_json()
        consulta = data.get('SELECT')

        cursor = db.cursor()
        cursor.execute(consulta)
        resultados = cursor.fetchall()

        respuesta = {'resultados': resultados}
        return jsonify(respuesta)

    except Exception as e:
        return jsonify({'error: no puede mostrar resultado': str(e)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

