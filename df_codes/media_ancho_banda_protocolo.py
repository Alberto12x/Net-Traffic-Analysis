from pyspark.sql import SparkSession
from pyspark.sql.functions import col, avg
import sys

"""
Módulo que calcula la media dle ancho de banda en bits por segundo de los distintos protocolos de red
"""

# Creamos la sesion de spark y ajustamos el nivel del logger a WARN
spark = SparkSession.builder.appName("Average Bandwidth by Protocol").getOrCreate()
spark.sparkContext.setLogLevel("WARN")

# Leer los argumentos de entrada y salida
input_path = sys.argv[1]
output_path = sys.argv[2]

# Leemos el archivo CSV
df = spark.read.csv(input_path, header=True, inferSchema=True)

# Casteamos la columna de Length a entero
df = df.withColumn("Length", col("Length").cast("integer"))

# Calculamos la media de ancho de banda por protocolo
avg_bandwidth_df = df.groupBy("Protocol").agg(avg("Length").alias("AverageLength"))

# Guardamos el resultado como archivo CSV
avg_bandwidth_df.write.option("header", "true").csv(output_path)

# Detenemos la sesión de Spark
spark.stop()
