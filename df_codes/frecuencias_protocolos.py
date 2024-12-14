from pyspark.sql import SparkSession
from pyspark.sql.functions import col, count
import sys

"""
Módulo que calcula la frecuenca de los protocolos de red
"""
# Creamos la sesion de spark y ajustamos el nivel del logger a WARN
spark = SparkSession.builder.appName("Protocol Frequencies").getOrCreate()
spark.sparkContext.setLogLevel("WARN")

# Leemos los argumentos de entrada y salida
input = sys.argv[1]
output = sys.argv[2]

# Leemos el CSV
df = spark.read.csv(input, header=True, inferSchema=True)

# Convertimos la columna Time a timestamp para mantener tipos consistentes con el resto del pipeline
df = df.withColumn("Time", col("Time").cast("timestamp"))

# Calculamos la frecuencia de los protocolos
protocol_freq_df = (
    df.groupBy("Protocol")
    .agg(count("*").alias("Frequency"))
    .orderBy("Frequency", ascending=False)
)

# Seleccionamos columnas relevantes
result = protocol_freq_df.select(col("Protocol"), col("Frequency"))

# Guardamos el resultado como archivo CSV
result.write.option("header", "true").csv(output)

# Detenemos la sesión de Spark
spark.stop()
