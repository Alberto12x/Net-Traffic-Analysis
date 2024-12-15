#!/bin/bash

# Colores para salida en consola
GREEN='\033[0;32m'
RESET='\033[0m'

# Función para mostrar la ayuda
show_help() {
    echo -e "${GREEN}Uso: $0 <ruta_dataset> <output_dir> <bucket> <master_vcpus> <worker_vcpus> <num_workers> [filter_bandwidth] [comparator] [top_k]${RESET}"
    echo -e "${GREEN}Parámetros:${RESET}"
    echo -e "  <ruta_dataset>       Ruta al dataset a procesar"
    echo -e "  <output_dir>         Directorio (bucket) donde se guardarán los resultados"
    echo -e "  <bucket>             Bucket que contiene lso codigos a ejecutar"
    echo -e "  <master_vcpus>       Número de vCPUs para el nodo maestro"
    echo -e "  <worker_vcpus>       Número de vCPUs para los nodos trabajadores"
    echo -e "  <num_workers>        Número de nodos trabajadores"
    echo -e "  [filter_bandwidth]   (Opcional) Ancho de banda para el filtro"
    echo -e "  [comparator]         (Opcional) Comparador para el filtro"
    echo -e "  [top_k]              (Opcional) Valor k para el top k"
    echo -e "  -h                   Mostrar este mensaje de ayuda"
    exit 0
}

# Variables de entrada
DATASET=$1
OUTPUT_DIR=$2
BUCKET=$3
MASTER_VCPUS=$4
WORKER_VCPUS=$5
NUM_WORKERS=$6
FILTER_BANDWIDTH=$7
COMPARATOR=$8
TOP_K=$9

# Comprobación de argumentos
if [[ "$1" == "-h" || "$2" == "-h" ]]; then
    show_help
fi

if [[ -z "$DATASET" || -z "$OUTPUT_DIR" || -z "$MASTER_VCPUS" || -z "$WORKER_VCPUS" || -z "$NUM_WORKERS" ]]; then
    echo -e "${GREEN}Uso: $0 <ruta_dataset> <output_dir> <master_vcpus> <worker_vcpus> <num_workers> [filter_bandwidth] [comparator] [top_k]${RESET}"
    exit 1
fi

# Variables de configuración para el clúster de GCP
CLUSTER_NAME="cluster-spark"
REGION="europe-southwest1"

<<<<<<< HEAD
=======
# Crear un paquete ZIP con dependencias
echo -e "${GREEN}Preparando dependencias para el clúster...${RESET}"
pip install -r requiriments.txt --target ./package
cd package && zip -r dependencies.zip . && cd ..

>>>>>>> origin/main
# Crear el clúster en GCP
echo -e "${GREEN}Creando el clúster en GCP...${RESET}"
start_time_total=$(date +%s)  # Medir el tiempo total de todas las tareas

start_time=$(date +%s)
gcloud dataproc clusters create $CLUSTER_NAME \
    --region=$REGION \
    --master-machine-type=e2-standard-$MASTER_VCPUS \
    --master-boot-disk-size=50 \
    --worker-machine-type=e2-standard-$WORKER_VCPUS \
    --worker-boot-disk-size=50 \
    --num-workers=$NUM_WORKERS \
    --enable-component-gateway
end_time=$(date +%s)
echo -e "${GREEN}Tiempo de creación del clúster: $((end_time - start_time)) segundos.${RESET}"

<<<<<<< HEAD
# Ejecutar trabajos de Spark con los recursos máximos
echo -e "${GREEN}Ejecutando programas de Python en el clúster de GCP...${RESET}"

echo -e "${GREEN}Ejecutando Ancho_banda.py${RESET}"
start_time=$(date +%s)
gcloud dataproc jobs submit pyspark $BUCKET/df_codes/ancho_banda.py \
    --cluster=$CLUSTER_NAME \
    --region=$REGION \
    --properties="spark.executor.cores=$WORKER_VCPUS,spark.executor.memory=8g,spark.driver.memory=8g,spark.executor.instances=$NUM_WORKERS" \
    -- \
    $DATASET \
    $OUTPUT_DIR/output_anchobanda
end_time=$(date +%s)
echo -e "${GREEN}Tiempo de ejecución de 'ancho_banda.py': $((end_time - start_time)) segundos.${RESET}"

echo -e "${GREEN}Ejecutando frecuencia_protocolos.py${RESET}"
start_time=$(date +%s)
gcloud dataproc jobs submit pyspark $BUCKET/df_codes/frecuencias_protocolos.py \
    --cluster=$CLUSTER_NAME \
    --region=$REGION \
    --properties="spark.executor.cores=$WORKER_VCPUS,spark.executor.memory=8g,spark.driver.memory=8g,spark.executor.instances=$NUM_WORKERS" \
=======
# Ejecutar trabajos de Spark
echo -e "${GREEN}Ejecutando programas de Python en el clúster de GCP...${RESET}"

start_time=$(date +%s)
gcloud dataproc jobs submit pyspark $BUCKET/df_codes/ancho_banda.py \
    --cluster=$CLUSTER_NAME\
    --region=$REGION\
    -- \
    $DATASET \
    $OUTPUT_DIR/ouput_anchobanda
end_time=$(date +%s)
echo -e "${GREEN}Tiempo de ejecución de 'ancho_banda.py': $((end_time - start_time)) segundos.${RESET}"

start_time=$(date +%s)
gcloud dataproc jobs submit pyspark $BUCKET/df_codes/frecuencias_protocolos.py \
    --cluster=$CLUSTER_NAME\
    --region=$REGION\
>>>>>>> origin/main
    -- \
    $DATASET \
    $OUTPUT_DIR/output_frecuencia_protocolos
end_time=$(date +%s)
echo -e "${GREEN}Tiempo de ejecución de 'frecuencias_protocolos.py': $((end_time - start_time)) segundos.${RESET}"

<<<<<<< HEAD
echo -e "${GREEN}Ejecutando inverted_index_flags.py${RESET}"
start_time=$(date +%s)
gcloud dataproc jobs submit pyspark $BUCKET/df_codes/inverted_index_flags.py \
    --cluster=$CLUSTER_NAME \
    --region=$REGION \
    --properties="spark.executor.cores=$WORKER_VCPUS,spark.executor.memory=8g,spark.driver.memory=8g,spark.executor.instances=$NUM_WORKERS" \
=======
start_time=$(date +%s)
gcloud dataproc jobs submit pyspark $BUCKET/df_codes/inverted_index_flags.py \
    --cluster=$CLUSTER_NAME\
    --region=$REGION\
>>>>>>> origin/main
    -- \
    $DATASET \
    $OUTPUT_DIR/output_inverted_index
end_time=$(date +%s)
echo -e "${GREEN}Tiempo de ejecución de 'inverted_index_flags.py': $((end_time - start_time)) segundos.${RESET}"

echo -e "${GREEN}Ejecutando media_ancho_banda_protocolo.py${RESET}"
start_time=$(date +%s)
gcloud dataproc jobs submit pyspark $BUCKET/df_codes/media_ancho_banda_protocolo.py \
    --cluster=$CLUSTER_NAME \
    --region=$REGION \
    --properties="spark.executor.cores=$WORKER_VCPUS,spark.executor.memory=8g,spark.driver.memory=8g,spark.executor.instances=$NUM_WORKERS" \
    -- \
    $DATASET \
    $OUTPUT_DIR/output_media_anchobanda_protocolos
end_time=$(date +%s)
echo -e "${GREEN}Tiempo de ejecución de 'media_ancho_banda_protocolo.py': $((end_time - start_time)) segundos.${RESET}"

echo -e "${GREEN}Ejecutando filtro_ancho_banda.py${RESET}"
start_time=$(date +%s)
gcloud dataproc jobs submit pyspark $BUCKET/df_codes/filtro_ancho_banda.py \
    --cluster=$CLUSTER_NAME \
    --region=$REGION \
    --properties="spark.executor.cores=$WORKER_VCPUS,spark.executor.memory=8g,spark.driver.memory=8g,spark.executor.instances=$NUM_WORKERS" \
    -- \
    $OUTPUT_DIR/output_anchobanda \
    $OUTPUT_DIR/filtro_ancho_banda \
    $FILTER_BANDWIDTH \
    $COMPARATOR
end_time=$(date +%s)
echo -e "${GREEN}Tiempo de ejecución de 'filtro_ancho_banda.py': $((end_time - start_time)) segundos.${RESET}"

echo -e "${GREEN}Ejecutando top_ancho_banda.py${RESET}"
start_time=$(date +%s)
gcloud dataproc jobs submit pyspark $BUCKET/df_codes/top_ancho_banda.py \
    --cluster=$CLUSTER_NAME \
    --region=$REGION \
    --properties="spark.executor.cores=$WORKER_VCPUS,spark.executor.memory=8g,spark.driver.memory=8g,spark.executor.instances=$NUM_WORKERS" \
    -- \
    $OUTPUT_DIR/output_anchobanda \
    $OUTPUT_DIR/outputs_top_anchobanda \
    $TOP_K
end_time=$(date +%s)
echo -e "${GREEN}Tiempo de ejecución de 'top_ancho_banda.py': $((end_time - start_time)) segundos.${RESET}"

echo -e "${GREEN}Ejecutando ips_ubicacion.py .py${RESET}"
start_time=$(date +%s)
gcloud dataproc jobs submit pyspark $BUCKET/df_codes/ips_ubicacion.py \
    --cluster=$CLUSTER_NAME \
    --region=$REGION \
    --properties="spark.executor.cores=$WORKER_VCPUS,spark.executor.memory=8g,spark.driver.memory=8g,spark.executor.instances=$NUM_WORKERS" \
    --py-files $BUCKET/dependencies.zip
    -- \
    $DATASET \
    $OUTPUT_DIR/output_ip_ubicacion \
    $BUCKET/GeoLite2-City.mmdb
end_time=$(date +%s)
echo -e "${GREEN}Tiempo de ejecución de 'ips_ubicacion.py': $((end_time - start_time)) segundos.${RESET}"

# Eliminar el clúster después de ejecutar los trabajos
echo -e "${GREEN}Eliminando el clúster...${RESET}"
start_time=$(date +%s)
gcloud dataproc clusters delete $CLUSTER_NAME --region=$REGION --quiet
end_time=$(date +%s)
echo -e "${GREEN}Tiempo de eliminación del clúster: $((end_time - start_time)) segundos.${RESET}"

# Tiempo total de ejecución (sin contar la eliminación del clúster)
end_time_total=$(date +%s)
total_time=$((end_time_total - start_time_total))
echo -e "${GREEN}Tiempo total de todas las tareas (sin eliminación del clúster): $total_time segundos.${RESET}"

# Mostrar mensaje de finalización
echo -e "${GREEN}Ejecución completa. Clúster eliminado y archivos del bucket borrados.${RESET}"
