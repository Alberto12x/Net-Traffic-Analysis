from pyspark.sql import SparkSession
from pyspark.sql.functions import col, avg
import sys

# Crear la sesión de Spark
spark = SparkSession.builder.appName("Average Bandwidth by Protocol").getOrCreate()

# Leer los argumentos de entrada y salida
input_path = sys.argv[1]  # Archivo CSV de entrada
output_path = sys.argv[2]  # Carpeta de salida

# Leer el archivo CSV
df = spark.read.csv(input_path, header=True, inferSchema=True)

# Convertir las columnas necesarias al tipo apropiado
df = df.withColumn("Length", col("Length").cast("integer"))

# Calcular la media de ancho de banda por protocolo
avg_bandwidth_df = df.groupBy("Protocol") \
                     .agg(avg("Length").alias("AverageLength"))

# Guardar el resultado como archivo CSV
avg_bandwidth_df.write.option("header", "true").csv(output_path)

# Detener la sesión de Spark
spark.stop()
