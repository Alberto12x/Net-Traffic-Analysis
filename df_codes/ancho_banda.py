from pyspark.sql import SparkSession
from pyspark.sql.functions import col, sum as _sum, window
import sys

# Crear la sesión de Spark
spark = SparkSession.builder.appName("Ancho_de_banda").getOrCreate()

# Leer los argumentos de entrada y salida
input = sys.argv[1]
output = sys.argv[2]

# Leer el CSV
df = spark.read.csv(input, header=True, inferSchema=True)

# Convertir la columna Time a timestamp y Length a entero
df = df.withColumn("Time", col("Time").cast("timestamp")) \
       .withColumn("Length", col("Length").cast("integer"))

# Calcular el ancho de banda por segundo, sumando todos los bytes y convirtiéndolos a bits
bandwidth_df = df.groupBy(window(col("Time"), "1 second")) \
                 .agg(_sum("Length").alias("TotalBytes")) \
                 .withColumn("Bandwidth_bps", col("TotalBytes") * 8)

# Seleccionar columnas relevantes
result = bandwidth_df.select(
    col("window.start").alias("start_time"),
    col("window.end").alias("end_time"),
    "TotalBytes",
    "Bandwidth_bps"
).orderBy("start_time")

# Guardar el resultado como CSV con los nombres de las columnas
result.write.option("header", "true") \
            .option("quote", "") \
            .csv(output)

# Detener la sesión de Spark
spark.stop()
