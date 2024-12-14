#!/bin/bash

# Definimos el nombre del entorno virtual y el directorio de salida
VENV_DIR=".venvGroup9Cloud"
OUTPUT_DIR="outputs"
GEO_LITE_FILE="./GeoLite2-City.mmdb"
GEO_LITE_URL=https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-City.mmdb
PYTHON_VERSION="3.12"

# Función para mostrar el mensaje de ayuda
show_help() {
    echo "Uso: ./script_ejecucion_local.sh <opciones>"
    echo ""
    echo "Opciones:"
    echo "  -h, --help                   Muestra este mensaje de ayuda."
    echo "  <ancho de banda para el filtro> <Comparador 1 > , 0 <= > <top k> <dataset>"
    echo "    - <ancho de banda para el filtro> es el valor límite de ancho de banda."
    echo "    - <Comparador> es el tipo de comparador para el filtro. Puede ser 1 o 0 siendo > y <= respectivamente."
    echo "    - <top k> es el valor k para el filtro Top-K."
    echo "    - <dataset> es la ubicación del archivo de datos para procesar."
    echo ""
    echo "Este script configura y ejecuta un conjunto de programas Python para procesar datos de red."
    echo "Crea un entorno virtual, instala las dependencias, y ejecuta los scripts de análisis."
}

# Función para comprobar si los argumentos fueron proporcionados correctamente
check_arguments() {
    if [[ $# -lt 4 ]]; then
        echo "Error: Se requieren al menos 4 argumentos. El formato es:"
        echo "./script_ejecucion_local.sh <ancho de banda para el filtro> <Comparador 1 > , 0 <= > <top k> <dataset>"
        exit 1
    fi
    echo "Argumentos recibidos correctamente."
    # Guardamos los argumentos en variables
    FILTER_BANDWIDTH=$1
    COMPARATOR=$2
    TOP_K=$3
    DATASET=$4
}

# Función para comprobar si Python 3.12 o mayor está instalado
check_python_version() {
    PYTHON_INSTALLED=$(python3 --version 2>&1)
    PYTHON_MAJOR_VERSION=$(echo $PYTHON_INSTALLED | cut -d ' ' -f2 | cut -d '.' -f1)
    PYTHON_MINOR_VERSION=$(echo $PYTHON_INSTALLED | cut -d ' ' -f2 | cut -d '.' -f2)

    if [[ "$PYTHON_MAJOR_VERSION" -ge 3 && "$PYTHON_MINOR_VERSION" -ge 12 ]]; then
        echo "Python 3.12 o mayor está instalado."
    else
        echo "Error: Python 3.12 o mayor no está instalado."
        echo "Por favor, instala la versión adecuada o actualiza Python."
        exit 1
    fi
}

# Función para crear un entorno virtual si no está activo
create_virtual_env() {
    if [[ -d $VENV_DIR ]]; then
        echo "El entorno virtual '$VENV_DIR' existe. Eliminando..."
        rm -rf $VENV_DIR
    fi

    echo "Creando entorno virtual..."
    python3 -m venv $VENV_DIR
    source $VENV_DIR/bin/activate
    echo "Entorno virtual activado."
}

# Función para instalar las dependencias desde 'requirements.txt'
install_requirements() {
    if [[ -f "requeriments.txt" ]]; then
        echo "Instalando dependencias desde 'requirements.txt'..."
        python3 -m pip install -r requeriments.txt
        if [[ $? -eq 0 ]]; then
            echo "Dependencias instaladas con éxito."
        else
            echo "Hubo un error al instalar las dependencias."
            exit 1
        fi
    else
        echo "No se encontró 'requirements.txt'."
        exit 1
    fi
}

# Función para comprobar y eliminar el directorio 'outputs' si existe
check_and_remove_outputs() {
    if [[ -d $OUTPUT_DIR ]]; then
        echo "El directorio '$OUTPUT_DIR' existe. Eliminando..."
        rm -rf $OUTPUT_DIR
    else
        echo "El directorio '$OUTPUT_DIR' no existe. Nada que eliminar."
    fi
}

# Función para comprobar si el archivo GeoLite2-City.mmdb existe y, si no, descargarlo
check_and_download_geo_lite() {
    if [[ ! -f "$GEO_LITE_FILE" ]]; then
        echo "El archivo '$GEO_LITE_FILE' no existe. Descargando..."
        curl -L -o "$GEO_LITE_FILE" "$GEO_LITE_URL"
        if [[ $? -eq 0 ]]; then
            echo "Archivo '$GEO_LITE_FILE' descargado con éxito."
        else
            echo "Hubo un error al descargar el archivo '$GEO_LITE_FILE'."
            exit 1
        fi
    else
        echo "El archivo '$GEO_LITE_FILE' ya existe."
    fi
}

# Función para ejecutar los programas de Python dentro del entorno virtual
run_python_programs() {
    echo "Ejecutando programas de Python dentro del entorno virtual..."

    echo "Ejecutando script: df_codes/ancho_banda.py"
    python3 df_codes/ancho_banda.py $DATASET $OUTPUT_DIR/output_anchobanda

    echo "Ejecutando script: df_codes/frecuencia_protocolos.py"
    python3 df_codes/frecuencias_protocolos.py $DATASET $OUTPUT_DIR/output_frecuencia_protocolos

    echo "Ejecutando script: df_codes/inverted_index_flags.py"
    python3 df_codes/inverted_index_flags.py $DATASET $OUTPUT_DIR/output_inverted_index

    echo "Ejecutando script: df_codes/media_ancho_banda_protocolo.py"
    python3 df_codes/media_ancho_banda_protocolo.py $DATASET $OUTPUT_DIR/output_media_anchobanda_protocolos

    echo "Ejecutando script: df_codes/filtro_ancho_banda.py"
    python3 df_codes/filtro_ancho_banda.py $OUTPUT_DIR/output_anchobanda $OUTPUT_DIR/outputs_filtro_anchobanda $FILTER_BANDWIDTH $COMPARATOR

    echo "Ejecutando script: df_codes/top_ancho_banda.py"
    python3 df_codes/top_ancho_banda.py $OUTPUT_DIR/output_anchobanda $OUTPUT_DIR/outputs_top_anchobanda $TOP_K

    echo "Ejecutando script: df_codes/ips_ubicacion"
    python3 df_codes/ips_ubicacion.py $DATASET $OUTPUT_DIR/output_ip_ubicacion ./GeoLite2-City.mmdb
}

# Comprobar si la opción -h o --help fue pasada
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Comprobar los argumentos pasados al script
check_arguments "$@"

# Comprobar si Python 3.12 o mayor está instalado
check_python_version

# Comprobar si el archivo GeoLite2-City.mmdb existe y, si no, descargarlo
check_and_download_geo_lite

# Crear entorno virtual (si no hay uno activo) y activarlo
create_virtual_env

# Instalar las dependencias desde 'requirements.txt'
install_requirements

# Comprobar que el directorio no exista
check_and_remove_outputs

# Ejecutar los programas de Python
run_python_programs

# Si el entorno virtual fue creado en este script, lo desactivamos y lo borramos
if [[ -z "$VIRTUAL_ENV" ]]; then
    deactivate
    echo "Desactivando el entorno virtual."

    # Borrar el entorno virtual si fue creado en este script
    rm -rf $VENV_DIR
    echo "El entorno virtual ha sido eliminado."
else
    echo "El entorno virtual activo no será desactivado ni eliminado."
fi
