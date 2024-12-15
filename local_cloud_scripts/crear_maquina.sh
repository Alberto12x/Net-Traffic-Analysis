#!/bin/bash

# Función para mostrar la ayuda
mostrar_ayuda() {
    echo "Uso: $0 -t TIPO_DE_MAQUINA [-h]"
    echo ""
    echo "Opciones:"
    echo "  -t TIPO_DE_MAQUINA   Especifica el tipo de máquina (e.g., e2-standard-4, custom-8-16384)"
    echo "  -h                   Muestra esta ayuda y termina"
    exit 0
}

# Variables por defecto
tipo_maquina=""

# Procesar argumentos
while getopts "t:h" opt; do
  case $opt in
    t)  # Tipo de máquina especificado
        tipo_maquina="$OPTARG"
        ;;
    h)  # Mostrar ayuda
        mostrar_ayuda
        ;;
    *)  # Opción inválida
        echo "Opción inválida. Usa -h para mostrar la ayuda."
        exit 1
        ;;
  esac
done

# Validar que se haya proporcionado el tipo de máquina
if [ -z "$tipo_maquina" ]; then
    echo "Error: Debes especificar un tipo de máquina con la opción -t."
    echo "Usa -h para más información."
    exit 1
fi

# Crear la instancia con el tipo de máquina proporcionado
echo "Creando instancia con tipo de máquina: $tipo_maquina"
gcloud compute instances create spark-local \
  --zone=europe-southwest1-a \
  --machine-type="$tipo_maquina" \
  --metadata-from-file startup-script=plantilla_cloud_local.sh

echo "Instancia creada exitosamente."
