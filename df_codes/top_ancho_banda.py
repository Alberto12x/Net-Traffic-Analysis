from pyspark.sql import SparkSession
from pyspark.sql.functions import col
import sys

# Crear la sesión de Spark
spark = SparkSession.builder.appName("Top K Seconds by Bandwidth").getOrCreate()

# Leer los argumentos de entrada y salida
input_path = sys.argv[1]
output = sys.argv[2]
k = int(sys.argv[3])  # El valor de k para el top K

# Leer todos los archivos CSV del directorio usando glob pattern
df = spark.read.csv(input_path, header=True, inferSchema=True)

# Seleccionar las columnas relevantes y ordenar por ancho de banda en orden descendente
top_k_df = df.select(
    col("start_time"),
    col("end_time"),
    col("TotalBytes"),
    col("Bandwidth_bps")
).orderBy(col("Bandwidth_bps").desc()).limit(k)

# Guardar el resultado como archivo CSV
top_k_df.write.option("header", "true").csv(output)

# Detener la sesión de Spark
spark.stop()
