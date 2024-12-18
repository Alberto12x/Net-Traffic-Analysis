#!/bin/bash

# Definimos los colores
GREEN='\e[32m'
RESET='\e[0m'

# Definimos el nombre del entorno virtual y el directorio de salida
VENV_DIR=".venvGroup9Cloud"
OUTPUT_DIR="outputs"
GEO_LITE_FILE="./GeoLite2-City.mmdb"
GEO_LITE_URL=https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-City.mmdb
PYTHON_VERSION="3.12"

# Función para mostrar el mensaje de ayuda
show_help() {
    echo -e "${GREEN}Uso: ./script_ejecucion_local.sh <opciones>${RESET}"
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
        echo -e "${GREEN}Error: Se requieren al menos 4 argumentos. El formato es:${RESET}"
        echo "./script_ejecucion_local.sh <ancho de banda para el filtro> <Comparador 1 > , 0 <= > <top k> <dataset>"
        exit 1
    fi
    echo -e "${GREEN}Argumentos recibidos correctamente.${RESET}"
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
        echo -e "${GREEN}Python 3.12 o mayor está instalado.${RESET}"
    else
        echo -e "${GREEN}Error: Python 3.12 o mayor no está instalado.${RESET}"
        echo -e "${GREEN}Por favor, instala la versión adecuada o actualiza Python.${RESET}"
        exit 1
    fi
}

# Función para crear un entorno virtual si no está activo
create_virtual_env() {
    if [[ -d $VENV_DIR ]]; then
        echo -e "${GREEN}El entorno virtual '$VENV_DIR' existe. Eliminando...${RESET}"
        rm -rf $VENV_DIR
    fi

    echo -e "${GREEN}Creando entorno virtual...${RESET}"
    python3 -m venv $VENV_DIR
    source $VENV_DIR/bin/activate
    echo -e "${GREEN}Entorno virtual activado.${RESET}"
}

# Función para instalar las dependencias desde 'requirements.txt'
install_requirements() {
    if [[ -f "requiriments.txt" ]]; then
        echo -e "${GREEN}Instalando dependencias desde 'requiriments.txt'...${RESET}"
        python3 -m pip install -r requiriments.txt
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}Dependencias instaladas con éxito.${RESET}"
        else
            echo -e "${GREEN}Hubo un error al instalar las dependencias.${RESET}"
            exit 1
        fi
    else
        echo -e "${GREEN}No se encontró 'requirements.txt'.${RESET}"
        exit 1
    fi
}

# Función para comprobar y eliminar el directorio 'outputs' si existe
check_and_remove_outputs() {
    if [[ -d $OUTPUT_DIR ]]; then
        echo -e "${GREEN}El directorio '$OUTPUT_DIR' existe. Eliminando...${RESET}"
        rm -rf $OUTPUT_DIR
    else
        echo -e "${GREEN}El directorio '$OUTPUT_DIR' no existe. Nada que eliminar.${RESET}"
    fi
}

# Función para comprobar si el archivo GeoLite2-City.mmdb existe y, si no, descargarlo
check_and_download_geo_lite() {
    if [[ ! -f "$GEO_LITE_FILE" ]]; then
        echo -e "${GREEN}El archivo '$GEO_LITE_FILE' no existe. Descargando...${RESET}"
        curl -L -o "$GEO_LITE_FILE" "$GEO_LITE_URL"
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}Archivo '$GEO_LITE_FILE' descargado con éxito.${RESET}"
        else
            echo -e "${GREEN}Hubo un error al descargar el archivo '$GEO_LITE_FILE'.${RESET}"
            exit 1
        fi
    else
        echo -e "${GREEN}El archivo '$GEO_LITE_FILE' ya existe.${RESET}"
    fi
}

# Función para ejecutar los programas de Python dentro del entorno virtual
run_python_programs() {
    echo -e "${GREEN}Ejecutando programas de Python dentro del entorno virtual...${RESET}"

    echo -e "${GREEN}Ejecutando script: df_codes/ancho_banda.py${RESET}"
    python3 df_codes/ancho_banda.py $DATASET $OUTPUT_DIR/output_anchobanda

    echo -e "${GREEN}Ejecutando script: df_codes/frecuencia_protocolos.py${RESET}"
    python3 df_codes/frecuencias_protocolos.py $DATASET $OUTPUT_DIR/output_frecuencia_protocolos

    echo -e "${GREEN}Ejecutando script: df_codes/inverted_index_flags.py${RESET}"
    python3 df_codes/inverted_index_flags.py $DATASET $OUTPUT_DIR/output_inverted_index

    echo -e "${GREEN}Ejecutando script: df_codes/media_ancho_banda_protocolo.py${RESET}"
    python3 df_codes/media_ancho_banda_protocolo.py $DATASET $OUTPUT_DIR/output_media_anchobanda_protocolos

    echo -e "${GREEN}Ejecutando script: df_codes/filtro_ancho_banda.py${RESET}"
    python3 df_codes/filtro_ancho_banda.py $OUTPUT_DIR/output_anchobanda $OUTPUT_DIR/outputs_filtro_anchobanda $FILTER_BANDWIDTH $COMPARATOR

    echo -e "${GREEN}Ejecutando script: df_codes/top_ancho_banda.py${RESET}"
    python3 df_codes/top_ancho_banda.py $OUTPUT_DIR/output_anchobanda $OUTPUT_DIR/outputs_top_anchobanda $TOP_K

    echo -e "${GREEN}Ejecutando script: df_codes/ips_ubicacion${RESET}"
    python3 df_codes/ips_ubicacion.py $DATASET $OUTPUT_DIR/output_ip_ubicacion ./GeoLite2-City.mmdb
}

# Comprobar si la opción -h o --help fue pasada
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

echo -e "${GREEN}Script de ejecucion en local.${RESET}"
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


echo -e "${GREEN}Desactivando el entorno virtual.${RESET}"

# Borrar el entorno virtual 
rm -rf $VENV_DIR
echo -e "${GREEN}El entorno virtual ha sido eliminado.${RESET}"
