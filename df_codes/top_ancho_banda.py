from pyspark.sql import SparkSession
from pyspark.sql.functions import col
import sys

"""
Módulo que devuelve un CSV con las k ventanas temporales de 1 segundo con mayor ancho de banda, se asume que se le pasa la salida de 
ancho_banda.py
"""

# Creamos la sesion de spark y ajustamos el nivel del logger a WARN
spark = SparkSession.builder.appName("Top K Seconds by Bandwidth").getOrCreate()
spark.sparkContext.setLogLevel("WARN")

# Leemos los argumentos de entrada y salida
input_path = sys.argv[1]
output = sys.argv[2]
k = int(sys.argv[3])  # El valor de k para el top K

# Leemos todos los archivos CSV del directorio
df = spark.read.csv(input_path, header=True, inferSchema=True)

# Seleccionamos las columnas relevantes y ordenar por ancho de banda en orden descendente
top_k_df = (
    df.select(
        col("start_time"), col("end_time"), col("TotalBytes"), col("Bandwidth_bps")
    )
    .orderBy(col("Bandwidth_bps").desc())
    .limit(k)
)

# Guardamos el resultado como archivo CSV
top_k_df.write.option("header", "true").csv(output)

# Detenemos la sesión de Spark
spark.stop()
