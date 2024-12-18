import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path
from geopy.geocoders import Nominatim
from pathlib import Path
import geopandas as gpd

"""
Script que realiza graficas con el output por de script_ejecucion_local.sh
"""


# Configuración del directorio y archivo
input_directory = Path("./outputs/output_anchobanda")  
output_directory = Path("./graficas") 
output_directory.mkdir(parents=True, exist_ok=True)  

# Detectar todos los archivos CSV en el directorio
dataframes = []
for csv_file in input_directory.glob("*.csv"):
    print(f"Leyendo archivo: {csv_file}")
    try:
        df = pd.read_csv(csv_file)
        dataframes.append(df)
    except Exception as e:
        print(f"Error al leer {csv_file}: {e}")

# Unir todos los DataFrames
if not dataframes:
    print("No se encontraron archivos CSV en el directorio.")
    exit()

combined_df = pd.concat(dataframes, ignore_index=True)

# Convertir start_time a datetime
combined_df["start_time"] = pd.to_datetime(combined_df["start_time"], errors="coerce")

# Crear la gráfica de puntos
plt.figure(figsize=(10, 6))
for column in combined_df.columns:
    if column not in ["start_time", "end_time"]:
        plt.scatter(combined_df["start_time"], combined_df[column], label=column, alpha=0.7)

plt.xscale("linear")
plt.yscale("log")  
plt.xlabel("Start Time")
plt.ylabel("Valores (escala logarítmica)")
plt.title("Ancho de banda")
plt.legend()
plt.grid(True, which="both", linestyle="--", linewidth=0.5)

# Guardar la gráfica como archivo JPEG
output_file = output_directory / "grafica_ancho_banda.jpeg"
plt.savefig(output_file, format="jpeg")
plt.close()

print(f"La gráfica de puntos ha sido guardada como {output_file}")

################################################################################################################################################################
################################################################################################################################################################
################################################################################################################################################################
################################################################################################################################################################


# Configuración del directorio y archivo
input_directory = Path("./outputs/output_frecuencia_protocolos")  
output_directory = Path("./graficas")  
output_directory.mkdir(parents=True, exist_ok=True) 

# Detectar todos los archivos CSV en el directorio
dataframes = []
for csv_file in input_directory.glob("*.csv"):
    print(f"Leyendo archivo: {csv_file}")
    try:
        df = pd.read_csv(csv_file)
        dataframes.append(df)
    except Exception as e:
        print(f"Error al leer {csv_file}: {e}")

# Unir todos los DataFrames
if not dataframes:
    print("No se encontraron archivos CSV en el directorio.")
    exit()

combined_df = pd.concat(dataframes, ignore_index=True)

plt.figure(figsize=(10, 6))
plt.bar(combined_df["Protocol"], combined_df["Frequency"], color="skyblue", alpha=0.7)
plt.xlabel("Protocolo")
plt.ylabel("Frecuencia")
plt.yscale("log")  
plt.title("Protocolos y frecuencias")
plt.xticks(rotation=45)  
plt.grid(True, which="both", linestyle="--", linewidth=0.5)
output_file = output_directory / "grafica_frecuencia_protocolos.jpeg"
plt.savefig(output_file, format="jpeg")
plt.close()
print(f"La gráfica de frecuencias ha sido guardada como {output_file}")



################################################################################################################################################################
################################################################################################################################################################
################################################################################################################################################################
################################################################################################################################################################


# Configuración del directorio y archivo
input_directory = Path("./outputs/output_media_anchobanda_protocolos")  
output_directory = Path("./graficas")  
output_directory.mkdir(parents=True, exist_ok=True) 

# Detectar todos los archivos CSV en el directorio
dataframes = []
for csv_file in input_directory.glob("*.csv"):
    print(f"Leyendo archivo: {csv_file}")
    try:
        df = pd.read_csv(csv_file)
        dataframes.append(df)
    except Exception as e:
        print(f"Error al leer {csv_file}: {e}")

# Unir todos los DataFrames
if not dataframes:
    print("No se encontraron archivos CSV en el directorio.")
    exit()

combined_df = pd.concat(dataframes, ignore_index=True)



plt.figure(figsize=(10, 6))
plt.bar(combined_df["Protocol"], combined_df["AverageLength"], color="skyblue", alpha=0.7)
plt.xlabel("Protocolo")
plt.yscale("log")  
plt.ylabel("Ancho de banda (bps)")
plt.title("Protocolo y Ancho de Banda")
plt.xticks(rotation=45)  # Rotar nombres del eje X 45 grados
plt.grid(True, which="both", linestyle="--", linewidth=0.5)
output_file = output_directory / "grafica_anchobanda_protocolos.jpeg"
plt.savefig(output_file, format="jpeg")
plt.close()
print(f"La gráfica de ancho de banda ha sido guardada como {output_file}")


################################################################################################################################################################
################################################################################################################################################################
################################################################################################################################################################
################################################################################################################################################################



# Configuración del directorio y archivo
input_directory = Path("./outputs/output_ip_ubicacion")  
output_directory = Path("./graficas")  #
output_directory.mkdir(parents=True, exist_ok=True) 

# Detectar todos los archivos CSV en el directorio
dataframes = []
for csv_file in input_directory.glob("*.csv"):
    print(f"Leyendo archivo: {csv_file}")
    try:
        df = pd.read_csv(csv_file)
        dataframes.append(df)
    except Exception as e:
        print(f"Error al leer {csv_file}: {e}")

# Unir todos los DataFrames
if not dataframes:
    print("No se encontraron archivos CSV en el directorio.")
    exit()

combined_df = pd.concat(dataframes, ignore_index=True)

data = combined_df

# Inicializar el geolocalizador
geolocator = Nominatim(user_agent="geo_locator")

# Obtener coordenadas para cada ciudad
def get_coordinates(row):
    try:
        location = geolocator.geocode(f"{row['City']}, {row['Country']}")
        if location:
            return pd.Series([location.latitude, location.longitude])
    except Exception as e:
        print(f"Error al geocodificar {row['City']}, {row['Country']}: {e}")
    return pd.Series([None, None])

print("Obteniendo coordenadas de las ciudades...")
data[["Latitude", "Longitude"]] = data.apply(get_coordinates, axis=1)
data = data.dropna(subset=["Latitude", "Longitude"])  # Elimina filas sin coordenadas

# Crear un GeoDataFrame
gdf = gpd.GeoDataFrame(data, geometry=gpd.points_from_xy(data["Longitude"], data["Latitude"]))

# Descargar y cargar un nuevo mapa del mundo
naturalearth_url = "https://naturalearth.s3.amazonaws.com/110m_cultural/ne_110m_admin_0_countries.zip"
world = gpd.read_file(naturalearth_url)

# Crear la gráfica
fig, ax = plt.subplots(figsize=(15, 10))
world.plot(ax=ax, color="lightgrey")
gdf.plot(ax=ax, color="red", markersize=20, label="Ciudades")

plt.title("Ciudades Marcadas en el Mapa del Mundo")
plt.legend()

# Guardar la gráfica como archivo JPEG
output_file = output_directory / "mapa_ciudades.jpeg"
plt.savefig(output_file, format="jpeg")
plt.close()

print(f"El mapa de ciudades ha sido guardado como {output_file}")
