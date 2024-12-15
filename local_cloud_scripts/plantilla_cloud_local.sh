#!/bin/bash

# Configurar variables de entorno para Spark y Java
echo "export JAVA_HOME=/usr/lib/jvm/default-java" >> /etc/profile.d/spark.sh
echo "export PATH=\$PATH:/usr/local/spark/bin" >> /etc/profile.d/spark.sh

# Actualizar paquetes y realizar instalación inicial
apt-get update
apt-get install -y default-jre python-is-python3 python3-venv

# Descargar e instalar Apache Spark
wget https://dlcdn.apache.org/spark/spark-3.5.3/spark-3.5.3-bin-hadoop3.tgz
tar xzf spark-3.5.3-bin-hadoop3.tgz
mv spark-3.5.3-bin-hadoop3 /usr/local/spark
rm spark-3.5.3-bin-hadoop3.tgz



