from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col,
    explode,
    split,
    lower,
    regexp_extract,
    collect_list,
    concat_ws,
)
import sys

"""
Módulo que crea un indice invertido con los distintos flags de la columna info
"""

# Creamos la sesión de Spark
spark = SparkSession.builder.appName("ProtocolFlags").getOrCreate()
# Establecer el nivel de log a WARN
spark.sparkContext.setLogLevel("WARN")

# Leemos los argumentos
input_path = sys.argv[1]
output_path = sys.argv[2]

# Leemos el archivo CSV
df = spark.read.csv(input_path, header=True, inferSchema=True)

# Renombramos la columna 'No.' para evitar problemas ya que el . lo identifica como entero
df = df.withColumnRenamed("No.", "PacketID")

# Obtenemos los flagas tcp
tcp_df = (
    df.filter(col("Protocol") == "TCP")
    .withColumn(
        "BracketContent", regexp_extract(col("Info"), r"\[([^\]]+)\]", 0)
    )  # Extraemos contenido de corchetes
    .filter(col("BracketContent") != "")  # Filtramos filas donde no hay corchetes
    .select(
        col("PacketID"), col("BracketContent").alias("Word")
    )  # Renombramos columna como "Word"
)

# Extraer métodos HTTP (GET, POST)
http_methods = {"get", "post"}
# Obtenemos el metodo usado en el mensaje HTTP
http_df = (
    df.filter(col("Protocol") == "HTTP")
    .withColumn("Words", split(col("Info"), "\\s+"))
    .select(col("PacketID"), explode(col("Words")).alias("Word"))
    .withColumn("Word", lower(col("Word")))
    .filter(col("Word").rlike(r"^(?:" + "|".join(http_methods) + r")$"))
    .select("PacketID", "Word")
)

# Obtenemos los distintos mensaje de la familia de protocolos TLS
tls_df = (
    df.filter(col("Protocol").startswith("TLS"))
    .withColumn("Word", col("Info"))  # Renombrar contenido directamente a "Word"
    .select("PacketID", "Word")
)

# Unimos todos los DataFrames (TCP, HTTP y TLS) en uno solo
combined_df = tcp_df.union(http_df).union(tls_df)

# Construimos el índice invertido: mapear palabras a los identificadores de paquetes
inverted_index_df = combined_df.groupBy("Word").agg(
    collect_list("PacketID").alias("PacketIDs")
)

# Convertimos la columna PacketIDs en un String para poder introducirlo en un archivo CSV
inverted_index_df = inverted_index_df.withColumn(
    "PacketIDs", concat_ws(",", col("PacketIDs"))
)

# Guardamos el índice invertido como archivo CSV
inverted_index_df.write.option("header", "true").csv(output_path)

# Detenemos la sesión de Spark
spark.stop()
