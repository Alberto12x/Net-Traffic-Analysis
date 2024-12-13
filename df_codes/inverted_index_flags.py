from pyspark.sql import SparkSession
from pyspark.sql.functions import col, explode, split, lower, regexp_extract, collect_list, concat_ws
import sys

# Crear la sesión de Spark
spark = SparkSession.builder.appName("ProtocolFlags").getOrCreate()

# Leer los argumentos
input_path = sys.argv[1]
output_path = sys.argv[2]

# Leer el archivo CSV en un DataFrame
df = spark.read.csv(input_path, header=True, inferSchema=True)

# Renombrar la columna 'No.' para evitar problemas
df = df.withColumnRenamed("No.", "PacketID")

# Extraer las palabras clave de los paquetes TCP (banderas como SYN, ACK, etc.)
tcp_flags = {"syn", "ack", "rst", "fin", "psh", "urg"}

tcp_df = df.filter(col("Protocol") == "TCP") \
    .withColumn("Words", split(col("Info"), "\\s+")) \
    .select(col("PacketID"), explode(col("Words")).alias("Word")) \
    .withColumn("Word", lower(col("Word"))) \
    .filter(col("Word").rlike(r'\[.*\]')) \
    .withColumn("Word", regexp_extract(col("Word"), r'\[([^\]]+)\]', 1)) \
    .filter(col("Word").rlike(r'^(?:' + "|".join(tcp_flags) + r')$')) \
    .select("PacketID", "Word")  # Seleccionamos solo las columnas necesarias

# Extraer métodos HTTP (GET, POST)
http_methods = {"get", "post"}

http_df = df.filter(col("Protocol") == "HTTP") \
    .withColumn("Words", split(col("Info"), "\\s+")) \
    .select(col("PacketID"), explode(col("Words")).alias("Word")) \
    .withColumn("Word", lower(col("Word"))) \
    .filter(col("Word").rlike(r'^(?:' + "|".join(http_methods) + r')$')) \
    .select("PacketID", "Word")  # Seleccionamos solo las columnas necesarias

# Extraer eventos TLS (Client Hello, Server Hello)
tls_events = {"client hello", "server hello"}

tls_df = df.filter(col("Protocol").startswith("TLS")) \
            .withColumn("Word", col("Info")) \
            .select("PacketID", "Word")  # Seleccionamos solo las columnas necesarias

# Unir todos los DataFrames (TCP, HTTP y TLS) en uno solo
combined_df = tcp_df.union(http_df).union(tls_df)

# Construir el índice invertido: mapear palabras a los identificadores de paquetes
inverted_index_df = combined_df.groupBy("Word") \
    .agg(collect_list("PacketID").alias("PacketIDs"))

# Convertir la columna PacketIDs en un String
inverted_index_df = inverted_index_df.withColumn("PacketIDs", concat_ws(",", col("PacketIDs")))

# Guardar el índice invertido como archivo CSV
inverted_index_df.write.option("header", "true").csv(output_path)

# Detener la sesión de Spark
spark.stop()
