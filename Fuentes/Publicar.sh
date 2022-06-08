 #!/bin/bash
# AGREGAR SINTAXIS AL LOG CRUDO, COPIARLO A DIRECTORIO VISIBLE Y PUBLICARLO

# VERIFICACION DE ARGUMENTOS, explicar uso si no se pasaron:
if [ $# -ne 2 ]; then
  echo "USO:
  Publicar Origen Destino
   donde:
    Origen es el log crudo original incluyendo path
      Si cese path ontiene archivos inihtml y finhtml se concatenan
      antes y despues del Origen y se cambia la extension por html
    Destino es el log formateado incluyendo path.
  Ej:
  Publicar.sh /Discos/Varios/Logs/Elec/202110_WAN1.log /Discos/www/Logs/index.html"
 exit
fi

# Publicar al directorio web local:
Inicio=$(dirname $1)/inihtml             	# Encabezado del HTML a generar
 Final=$(dirname $1)/finhtml             	# Final del HTML a generar
cat $Inicio $1 $Final > $2               	# Concatenar inicio de html, datos + final del html al archivo destino
cp $2 $(dirname $2)/$(basename $1).html  	# Copiar el archivo publicado a uno con el nombre original, para no sobreescribirlo
TZ=":America/Caracas" date +'%H:%M' > $2.tag	# Crear un archivo solo con la hora de la publicacion, para detectar cambios
# md5sum $2 | cut -c1-4 > $2.md5                # Calcular un checksum y guardar un pedacito, para detectar cambios

# Degug:
echo DIR DE ESTE SCRIPT: ${0%/*} > ${0%/*}/Publicar.sh.log
echo INICIO DEL HTML:  $Inicio >> ${0%/*}/Publicar.sh.log
echo LOG CRUDO: $1 >> ${0%/*}/Publicar.sh.log
echo FINAL DEL HTML: $Final >> ${0%/*}/Publicar.sh.log
echo HTML COMPLETO: $2 >> ${0%/*}/Publicar.sh.log
echo BAK MES: "cp $2 $(dirname $2)/$(basename $1).html" >> ${0%/*}/Publicar.sh.log

# Publicar a GitHub pages
Ahora=$(TZ=":America/Caracas" date +'%Y-%m-%d_%H:%M')
cd $(dirname $2)
git add .
git commit -m "Update del $Ahora" >> ${0%/*}/Publicar.sh.log
git push -u origin main >> ${0%/*}/Publicar.sh.log

# Publicar a Google sites
### PENDIENTE ###

# Publicar a Dropbox:
# SubDir=$(dirname $1)            # Tomar el directorio donde esta el archivo original
# SubDir=$(basename $SubDir)      # Y separar el ultimo nivel de subdirectorio
# /Discos/Alfica/Scripts/dropbox_uploader.sh upload $Dest /Logs/Alfica/$SubDir/$(basename $Dest) >> /tmp/LogConex/dropbox.log
# echo "DirectoryIndex "$(basename $Dest) > $(dirname $Dest)/.htaccess
# echo $Dest > /tmp/LogConex/debug_$SubDir.txt
# echo /Logs/Alfica/$SubDir/$(basename $Dest)  >>  /tmp/LogConex/debug_$SubDir.txt

# SinExt=$(basename $1)                 # Separar el nombre del archivo del directorio donde esta
# SinExt="${SinExt%%.*}"                # Separar el nombre del archivo de su extension
# Dest=$2/$SinExt.html                  # Componer el directorio y nombre completo del archivo destino


