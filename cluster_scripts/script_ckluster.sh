#!/bin/bash

# Colores para salida en consola
GREEN='\033[0;32m'
RESET='\033[0m'

# Función para mostrar la ayuda
show_help() {
    echo -e "${GREEN}Uso: $0 <ruta_dataset> <output_dir> <master_vcpus> <worker_vcpus> <num_workers> [filter_bandwidth] [comparator] [top_k] [num_threads]${RESET}"
    echo -e "${GREEN}Parámetros:${RESET}"
    echo -e "  <ruta_dataset>       Ruta al dataset a procesar"
    echo -e "  <output_dir>         Directorio (bucket) donde se guardarán los resultados"
    echo -e "  <master_vcpus>       Número de vCPUs para el nodo maestro"
    echo -e "  <worker_vcpus>       Número de vCPUs para los nodos trabajadores"
    echo -e "  <num_workers>        Número de nodos trabajadores"
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
MASTER_VCPUS=$3
WORKER_VCPUS=$4
NUM_WORKERS=$5
FILTER_BANDWIDTH=$6
COMPARATOR=$7
TOP_K=$8
NUM_THREADS=$9

# Comprobación de argumentos
if [[ "$1" == "-h" || "$2" == "-h" ]]; then
    show_help
fi

if [[ -z "$DATASET" || -z "$OUTPUT_DIR" || -z "$MASTER_VCPUS" || -z "$WORKER_VCPUS" || -z "$NUM_WORKERS" ]]; then
    echo -e "${GREEN}Uso: $0 <ruta_dataset> <output_dir> <master_vcpus> <worker_vcpus> <num_workers> [filter_bandwidth] [comparator] [top_k] [num_threads]${RESET}"
    exit 1
fi

# Si no se pasa num_threads, se usa 1 por defecto
if [[ -z "$NUM_THREADS" ]]; then
    NUM_THREADS=1
fi

# Crear directorio de salida si no existe, o borrarlo si ya existe
echo -e "${GREEN}Creando directorio de salida si no existe...${RESET}"
if [[ -d "$OUTPUT_DIR" ]]; then
    echo -e "${GREEN}El directorio de salida ya existe. Borrándolo...${RESET}"
    rm -rf "$OUTPUT_DIR"
fi

mkdir -p "$OUTPUT_DIR"

# Variables de configuración para el clúster de GCP
CLUSTER_NAME="cluster-spark"
REGION="europe-southwest1"

# Crear el clúster en GCP
echo -e "${GREEN}Creando el clúster en GCP...${RESET}"
gcloud dataproc clusters create $CLUSTER_NAME \
    --region=$REGION \
    --master-machine-type=e2-standard-$MASTER_VCPUS \
    --master-boot-disk-size=50GB \
    --worker-machine-type=e2-standard-$WORKER_VCPUS \
    --worker-boot-disk-size=50GB \
    --num-workers=$NUM_WORKERS

# Esperar hasta que el clúster esté listo
echo -e "${GREEN}Esperando que el clúster esté listo para su uso...${RESET}"
gcloud dataproc clusters wait $CLUSTER_NAME --region=$REGION

# Activar el entorno virtual e instalar dependencias
python -m venv venv
source venv/bin/activate
pip install -r requiriments.txt

# Función para ejecutar el trabajo con Spark
run_spark_submit() {
    SCRIPT=$1
    INPUT=$2
    OUTPUT=$3
    EXTRA_ARGS=$4

    echo -e "${GREEN}Ejecutando script: $SCRIPT${RESET}"

    # Ejecutar el trabajo PySpark
    gcloud dataproc jobs submit pyspark --cluster=$CLUSTER_NAME \
        --region=$REGION $SCRIPT -- $INPUT $OUTPUT $EXTRA_ARGS
}

# Ejecutar trabajos de Spark
echo -e "${GREEN}Ejecutando programas de Python en el clúster de GCP...${RESET}"

run_spark_submit "df_codes/ancho_banda.py" $DATASET "$OUTPUT_DIR/output_anchobanda"
run_spark_submit "df_codes/frecuencias_protocolos.py" $DATASET "$OUTPUT_DIR/output_frecuencia_protocolos"
run_spark_submit "df_codes/inverted_index_flags.py" $DATASET "$OUTPUT_DIR/output_inverted_index"
run_spark_submit "df_codes/media_ancho_banda_protocolo.py" $DATASET "$OUTPUT_DIR/output_media_anchobanda_protocolos"
run_spark_submit "df_codes/filtro_ancho_banda.py" "$OUTPUT_DIR/output_anchobanda" "$OUTPUT_DIR/outputs_filtro_anchobanda" "$FILTER_BANDWIDTH $COMPARATOR"
run_spark_submit "df_codes/top_ancho_banda.py" "$OUTPUT_DIR/output_anchobanda" "$OUTPUT_DIR/outputs_top_anchobanda" "$TOP_K"
run_spark_submit "df_codes/ips_ubicacion.py" $DATASET "$OUTPUT_DIR/output_ip_ubicacion" "./GeoLite2-City.mmdb"

# Deactivar el entorno virtual
deactivate
rm -rf venv

# Eliminar el clúster después de ejecutar los trabajos
echo -e "${GREEN}Eliminando el clúster...${RESET}"
gcloud dataproc clusters delete $CLUSTER_NAME --region=$REGION --quiet

# Mostrar mensaje de finalización
echo -e "${GREEN}Ejecución completa. Clúster eliminado.${RESET}"
