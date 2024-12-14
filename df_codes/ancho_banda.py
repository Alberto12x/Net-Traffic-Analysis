from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col,
    sum as _sum,
    min as _min,
    max as _max,
    avg as _avg,
    count,
    window,
)
import sys

"""
Mṕdulo que calcula el ancho de banda en bits por segundo, agrupa los paquetes en ventanas de 1 segundo, además de los paquete en esa ventana temporal se calcula
el paquete con menor longitud, mayor longitud,cantidad de paquetes, total de bytes y media de bits.
"""

# Creamos la sesion de spark y ajustamos el nivel del logger a WARN
spark = SparkSession.builder.appName("Ancho_de_banda").getOrCreate()
spark.sparkContext.setLogLevel("WARN")

# Leemos los argumentos de entrada y salida
input = sys.argv[1]
output = sys.argv[2]

# Leemos el CSV
df = spark.read.csv(input, header=True, inferSchema=True)

# Casteamos las columnas necesarias
df = df.withColumn("Time", col("Time").cast("timestamp")).withColumn(
    "Length", col("Length").cast("integer")
)

# Calculamos métricas por ventana de 1 segundo
bandwidth_df = (
    df.groupBy(window(col("Time"), "1 second"))  # Agrupamos por ventana de 1 segundo
    .agg(
        _sum("Length").alias("TotalBytes"),
        _min("Length").alias("MinLength"),
        _max("Length").alias("MaxLength"),
        count("Length").alias("PacketCount"),
        _avg("Length").alias("AvgLength"),
    )
    .withColumn("Bandwidth_bps", col("TotalBytes") * 8)
)

# Seleccionarmos columnas relevantes
result = bandwidth_df.select(
    col("window.start").alias("start_time"),
    col("window.end").alias("end_time"),
    "TotalBytes",
    "Bandwidth_bps",
    "MinLength",
    "MaxLength",
    "PacketCount",
    "AvgLength",
).orderBy(
    "start_time"
)  # Ordenamos por orden ascendente por la fecha de inicio de la ventana

# Guardamos el resultado como CSV incl
result.write.option("header", "true").option("quote", "").csv(output)

# Detenemos la sesión de Spark
spark.stop()
