from pyspark.sql import SparkSession
from pyspark.sql.functions import col, udf, split
from pyspark.sql.types import StringType
from geoip2.database import Reader
import sys

"""
Módulo que saca la ciudad y país de los distintas ips , tanto source como destination. Se muestran sin repeticiones
"""


# Función para obtener la geolocalización de una IP
def get_geo_info(ip, geo_db_path):
    try:
        geo_reader = Reader(geo_db_path)
        response = geo_reader.city(ip)
        country = response.country.name or "Unknown"
        city = response.city.name or "Unknown"
        geo_reader.close()
        return f"{country},{city}"
    except Exception:
        return "Unknown,Unknown"


# Convertimos la funcion a UDF para poder aplicarla en columnas
def geo_info_udf(geo_db_path):
    def inner_udf(ip):
        return get_geo_info(ip, geo_db_path)

    return udf(inner_udf, StringType())


# Creamos la sesion de spark y ajustamos el nivel del logger a WARN
spark = SparkSession.builder.appName("Geolocation Extraction").getOrCreate()
spark.sparkContext.setLogLevel("WARN")

# Leemos las rutas de entrada, salida y la base de datos GeoLite2
input_path = sys.argv[1]
output_path = sys.argv[2]
geo_db_path = sys.argv[3]  # Ruta a la base de datos GeoLite2-City.mmdb

# Leemos el archivo CSV en un DataFrame
df = spark.read.csv(input_path, header=True, inferSchema=True)

# Unimos las columnas Source y Destination, y obtener IPs únicas
ips_df = (
    df.select(col("Source").alias("IP"))
    .union(df.select(col("Destination").alias("IP")))
    .distinct()
)

# Aplicamos la geolocalización usando la función UDF creada
geo_udf = geo_info_udf(geo_db_path)
geolocated_df = ips_df.withColumn("GeoInfo", geo_udf(col("IP")))

# Separamos la columna GeoInfo en Country y City (usando 'split')
split_geo = (
    geolocated_df.withColumn("GeoInfoSplit", split(col("GeoInfo"), ","))
    .withColumn("Country", col("GeoInfoSplit").getItem(0))
    .withColumn("City", col("GeoInfoSplit").getItem(1))
)

# Eliminamos duplicados en Country y City
unique_geo_df = split_geo.select("Country", "City").distinct()

# Guardamos el resultado como archivo CSV
unique_geo_df.write.option("header", "true").csv(output_path)


# Detenemos la sesión de Spark
spark.stop()
