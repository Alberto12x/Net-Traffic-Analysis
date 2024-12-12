from pyspark.sql import SparkSession
from pyspark.sql.functions import col, count
import sys

# Crear la sesión de Spark
spark = SparkSession.builder.appName("Protocol Frequencies").getOrCreate()

# Leer los argumentos de entrada y salida
input = sys.argv[1]
output = sys.argv[2]

# Leer el CSV
df = spark.read.csv(input, header=True, inferSchema=True)

# Convertir la columna Time a timestamp (opcional para mantener tipos consistentes)
df = df.withColumn("Time", col("Time").cast("timestamp"))

# Calcular la frecuencia de los protocolos
protocol_freq_df = df.groupBy("Protocol") \
                     .agg(count("*").alias("Frequency")) \
                     .orderBy("Frequency", ascending=False)

# Seleccionar columnas relevantes
result = protocol_freq_df.select(
    col("Protocol"),
    col("Frequency")
)

# Guardar el resultado como archivo CSV
result.write.option("header", "true").csv(output)

# Detener la sesión de Spark
spark.stop()
