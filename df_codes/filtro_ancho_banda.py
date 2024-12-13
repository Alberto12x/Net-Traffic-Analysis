from pyspark.sql import SparkSession
from pyspark.sql.functions import col
import sys

# Crear la sesión de Spark
spark = SparkSession.builder.appName("Filter Bandwidth").getOrCreate()

# Leer los argumentos de entrada
input_path = sys.argv[1]  # Archivo CSV de entrada
output_path = sys.argv[2]  # Carpeta de salida
threshold = int(sys.argv[3])  # Ancho de banda mínimo
comparador = int(sys.argv[4])  # comparador


# Leer el archivo CSV
df = spark.read.csv(input_path, header=True, inferSchema=True)

# Filtrar los registros donde Bandwidth_bps es mayor que el umbral
filtered_df = (
    df.filter(col("Bandwidth_bps") > threshold)
    if comparador == 0
    else df.filter(col("Bandwidth_bps") <= threshold)
)


# Guardar el resultado como archivo CSV
filtered_df.write.option("header", "true").csv(output_path)

# Detener la sesión de Spark
spark.stop()
