from pyspark.sql import SparkSession
from pyspark.sql.functions import col
import sys

"""
Módulo que filtra el ancho de banda en la ventan de 1 segundo segun un umbra recibido por argumento y un comparador recibido por argumento. Se asume que el
archivo de entrada es el output de ancho_banda.py
"""
# Creamos la sesion de spark y ajustamos el nivel del logger a WARN
spark = SparkSession.builder.appName("Filter Bandwidth").getOrCreate()
spark.sparkContext.setLogLevel("WARN")

# Leemos los argumentos de entrada
input_path = sys.argv[1]
output_path = sys.argv[2]
threshold = int(sys.argv[3])  # Ancho de banda mínimo
comparador = int(sys.argv[4])  # comparador


# Leemos el archivo CSV
df = spark.read.csv(input_path, header=True, inferSchema=True)

# Filtramos los registros donde Bandwidth_bps es mayor que el umbral
filtered_df = (
    df.filter(col("Bandwidth_bps") > threshold)
    if comparador == 0
    else df.filter(col("Bandwidth_bps") <= threshold)
)


# Guardamos el resultado como archivo CSV
filtered_df.write.option("header", "true").csv(output_path)

# Detenemos la sesión de Spark
spark.stop()
