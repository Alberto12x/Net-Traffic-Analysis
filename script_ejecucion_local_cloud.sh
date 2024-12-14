#!/bin/bash

# Mostrar mensaje de ayuda
show_help() {
    echo "Uso: $0 -b BUCKET_NAME -o OUTPUT_DIR -m MASTER_URL"
    echo
    echo "Opciones:"
    echo "  -b BUCKET_NAME  Nombre del bucket de Google Cloud Storage donde se guardarán los resultados."
    echo "  -o OUTPUT_DIR   Nombre del directorio de salida en el bucket."
    echo "  -m MASTER_URL   Parámetro --master para spark-submit (por ejemplo, local[2])."
    echo "  -h              Muestra este mensaje de ayuda."
    exit 1
}

# Validar argumentos
bucket_name=""
output_dir="outputs"
master_url="local[2]"
while getopts "b:o:m:h" opt; do
    case ${opt} in
        b)
            bucket_name=${OPTARG}
            ;;
        o)
            output_dir=${OPTARG}
            ;;
        m)
            master_url=${OPTARG}
            ;;
        h)
            show_help
            ;;
        *)
            show_help
            ;;
    esac
done

if [ -z "$bucket_name" ]; then
    echo "Error: El nombre del bucket es obligatorio."
    show_help
fi

# Configurar variables de entorno para Spark y Java
echo "export JAVA_HOME=/usr/lib/jvm/default-java" >> /etc/profile.d/spark.sh
echo "export PATH=\$PATH:/usr/local/spark/bin" >> /etc/profile.d/spark.sh

# Actualizar paquetes y realizar instalación inicial
apt-get update
apt-get install -y default-jre python-is-python3 python3-venv

# Descargar e instalar Apache Spark
wget https://dlcdn.apache.org/spark/spark-3.5.3/spark-3.5.3-bin-hadoop3.tgz
tar xzf spark-3.5.3-bin-hadoop3.tgz
mv spark-3.5.3-bin-hadoop3 /usr/local/spark
rm spark-3.5.3-bin-hadoop3.tgz

# Crear un entorno virtual de Python
mkdir -p /opt/virtualenvs
python3 -m venv /opt/virtualenvs/spark_env

# Activar el entorno virtual e instalar dependencias
source /opt/virtualenvs/spark_env/bin/activate
if [ -f requirements.txt ]; then
    pip install --upgrade pip
    pip install -r requirements.txt
else
    echo "requirements.txt no encontrado. Por favor, proporcione el archivo en el directorio actual."
fi

deactivate

# Función para ejecutar Spark y guardar resultados
execute_spark_jobs() {
    local bucket_name=$1
    local output_dir=$2
    local master_url=$3

    # Conectar a GCP y limpiar directorios existentes
    echo "Conectando a Google Cloud Storage..."
    if gsutil ls gs://$bucket_name/$output_dir &>/dev/null; then
        echo "Directorio de resultados existente, eliminando..."
        gsutil -m rm -r gs://$bucket_name/$output_dir
    fi

    # Crear un nuevo directorio para los resultados
    gsutil mkdir -p gs://$bucket_name/$output_dir

    total_start_time=$(date +%s)

    # # Ejemplo de ejecuciones de Spark (reemplazar con tus comandos reales)
    # for job in job1.py job2.py; do
    #     echo "Ejecutando spark-submit para $job..."
    #     job_start_time=$(date +%s)

    #     /usr/local/spark/bin/spark-submit --master $master_url /path/to/jobs/$job >> /tmp/spark_job_${job}.log 2>&1

    #     job_end_time=$(date +%s)
    #     echo "Tiempo de ejecución para $job: $((job_end_time - job_start_time)) segundos."

    #     # Subir los resultados al bucket
    #     echo "Subiendo resultados para $job..."
    #     gsutil cp /tmp/spark_job_${job}.log gs://$bucket_name/$output_dir/
    # done

    total_end_time=$(date +%s)
    echo "Tiempo total de ejecución de todos los trabajos: $((total_end_time - total_start_time)) segundos."

    echo "Todos los trabajos completados y resultados almacenados en gs://$bucket_name/$output_dir"
}

# Crear y conectar la instancia en Google Cloud
create_and_setup_instance() {
    local instance_name="spark-local"
    local zone="europe-southwest1-a"
    local machine_type="e2-standard-4"

    echo "Creando instancia en Google Cloud..."
    gcloud compute instances create $instance_name --zone=$zone \
        --machine-type=$machine_type --metadata-from-file startup-script=plantilla_cloud_local.sh

    echo "Esperando que la máquina esté lista..."
    sleep 60

    echo "Conectándose por SSH a la instancia $instance_name..."
    gcloud compute ssh $instance_name --zone=$zone --command "bash -s" << EOF
    $(declare -f execute_spark_jobs)
    execute_spark_jobs $bucket_name $output_dir $master_url
EOF

    echo "Eliminando la instancia $instance_name..."
    gcloud compute instances delete $instance_name --zone=$zone --quiet
}

# Ejecutar la función principal
create_and_setup_instance

# Mensaje de finalización
echo "Script finalizado. Revisa el bucket en Google Cloud Storage para los resultados."
