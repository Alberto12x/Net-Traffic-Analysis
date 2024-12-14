#!/bin/bash

# Colores para salida en consola
GREEN='\033[0;32m'
RESET='\033[0m'

# Mostrar mensaje de ayuda
show_help() {
    echo -e "${GREEN}Uso: $0 <ruta_dataset> <output_dir> [filter_bandwidth] [comparator] [top_k] [num_threads]${RESET}"
    echo -e "${GREEN}Parámetros:${RESET}"
    echo -e "  <ruta_dataset>       Ruta al dataset a procesar"
    echo -e "  <output_dir>         Directorio donde se guardarán los resultados"
    echo -e "  [filter_bandwidth]   (Opcional) Ancho de banda para el filtro"
    echo -e "  [comparator]         (Opcional) Comparador para el filtro"
    echo -e "  [top_k]              (Opcional) Valor k para el top k"
    echo -e "  [num_threads]        (Opcional) Número de hilos para Spark (local[i])"
    echo -e "  -h                   Mostrar este mensaje de ayuda"
    exit 0
}

# Variables de entrada
DATASET=$1
OUTPUT_DIR=$2
FILTER_BANDWIDTH=$3
COMPARATOR=$4
TOP_K=$5
NUM_THREADS=$6

# Comprobación de argumentos
if [[ "$1" == "-h" || "$2" == "-h" ]]; then
    show_help
fi

if [[ -z "$DATASET" || -z "$OUTPUT_DIR" ]]; then
    echo -e "${GREEN}Uso: $0 <ruta_dataset> <output_dir> [filter_bandwidth] [comparator] [top_k] [num_threads]${RESET}"
    exit 1
fi

# Si no se pasa num_threads, se usa 1 por defecto
if [[ -z "$NUM_THREADS" ]]; then
    NUM_THREADS=1
fi

# Crear directorio de salida si no existe
mkdir -p "$OUTPUT_DIR"

# Variable para almacenar el tiempo total
TOTAL_TIME=0

# Función para ejecutar spark-submit y calcular el tiempo
run_spark_submit() {
    SCRIPT=$1
    INPUT=$2
    OUTPUT=$3
    EXTRA_ARGS=$4

    echo -e "${GREEN}Ejecutando script: $SCRIPT${RESET}"

    # Calcular el tiempo de ejecución
    START_TIME=$(date +%s)
    time spark-submit --master local[$NUM_THREADS] $SCRIPT $INPUT $OUTPUT $EXTRA_ARGS
    END_TIME=$(date +%s)

    # Calcular y mostrar el tiempo transcurrido
    EXECUTION_TIME=$((END_TIME - START_TIME))
    echo -e "${GREEN}Tiempo de ejecución de $SCRIPT: $EXECUTION_TIME segundos.${RESET}"

    # Acumular el tiempo total
    TOTAL_TIME=$((TOTAL_TIME + EXECUTION_TIME))
}

# Ejecutar scripts con spark-submit y calcular tiempo
echo -e "${GREEN}Ejecutando programas de Python dentro del entorno Spark con $NUM_THREADS hilos...${RESET}"

run_spark_submit "df_codes/ancho_banda.py" $DATASET "$OUTPUT_DIR/output_anchobanda"
run_spark_submit "df_codes/frecuencias_protocolos.py" $DATASET "$OUTPUT_DIR/output_frecuencia_protocolos"
run_spark_submit "df_codes/inverted_index_flags.py" $DATASET "$OUTPUT_DIR/output_inverted_index"
run_spark_submit "df_codes/media_ancho_banda_protocolo.py" $DATASET "$OUTPUT_DIR/output_media_anchobanda_protocolos"
run_spark_submit "df_codes/filtro_ancho_banda.py" "$OUTPUT_DIR/output_anchobanda" "$OUTPUT_DIR/outputs_filtro_anchobanda" "$FILTER_BANDWIDTH $COMPARATOR"
run_spark_submit "df_codes/top_ancho_banda.py" "$OUTPUT_DIR/output_anchobanda" "$OUTPUT_DIR/outputs_top_anchobanda" "$TOP_K"
run_spark_submit "df_codes/ips_ubicacion.py" $DATASET "$OUTPUT_DIR/output_ip_ubicacion" "./GeoLite2-City.mmdb"

# Mostrar el tiempo total
echo -e "${GREEN}Tiempo total de ejecución: $TOTAL_TIME segundos.${RESET}"

echo -e "${GREEN}Ejecución completa.${RESET}"
