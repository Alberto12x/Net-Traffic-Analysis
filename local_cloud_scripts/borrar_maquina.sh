#!/bin/bash

# Función para mostrar el mensaje de ayuda
show_help() {
    echo "Uso: $0 [-h]"
    echo
    echo "Opciones:"
    echo "  -h    Muestra este mensaje de ayuda y sale."
    echo
    echo "Este script elimina la instancia 'spark-local' en Google Cloud Compute."
}

# Comprobar si se pasó la opción -h
while getopts "h" opt; do
  case ${opt} in
    h)
      show_help
      exit 0
      ;;
    \?)
      show_help
      exit 1
      ;;
  esac
done

# Eliminar la instancia de Google Cloud
gcloud compute instances delete spark-local --zone=europe-southwest1-a --quiet
