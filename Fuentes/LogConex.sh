#!/bin/bash
# VERIFICAR CONEXION AL IP Y REGISTRAR

main() {
  # VERIFICACION DE ARGUMENTOS, explicar uso si no se pasaron:
  if [ $# -eq 0 ]; then
    echo "USO:
    LogConex [prefijo [sufijo]
     donde:
      IP = el IP a verificar conexion
      prefijo = string que precede a la fecha en el nombre de archivo, incluyendo el directorio
      sufijo = string que sigue a la fecha en nombre de archivo, incluyendo la extension
     ej.: LogConex 8.8.8.8 /Algun/Dir/Que/Exista/ _Google.log"
    exit
  fi

  # ASIGNACION DE VARIABLES:
  IP=$1                                              # IP a conectar
  Pre=$2                                             # Prefijo del archivo de registro
  Pos=$3                                             # Sufijo  del archivo de registro
  Tot=5                                              # Veces a intentarlo
  Sn="\*"                                            # Marca de online (el * es especial y hay que escaparlo con \) (registrar 1~A segu$
  Sp="#"                                             # Marca de online hora en punto
  Nn="-"                                             # Marca de offline
  Np="+"                                             # Marca de offline hora en punto
  Fn="."                                             # Marca de no registrado
  Fp=","                                             # Marca de no registrado hora en punto
  M=$(TZ=":America/Caracas" date +'%M')              # Determinar el minuto actual
  Md=$(( ${M#0}%10 ))                                # Calcular el minuto desde la decena
  Log=$Pre$(TZ=":America/Caracas" date +'%Y%m')$Pos  # Componer el nombre del archivo de registro
  COL=/tmp/LogConex/VecesOnline$Pos                  # Contador de veces online en 10 minutos

  # VERIFICACION / CREACION DEL ARCHIVO DE REGISTRO:
  if [ ! -f $Log ]; then                             # Si el archivo NO existe,
    CrearLogMes $Log $Fn $Fp                         #  crearlo, con los "placeholders" especificados para "en punto" y normal
  fi
  mkdir -p /tmp/LogConex                             # Creacion del directorio temporal (-p para que no de error si existe)

  touch $COL                                         # Por si no existe el contador de minutos online, crearlo vacio

  # Con ping (mas ligero pero no diferenciable por URL en firewall)
  # Resp=$(ping -W 1 -c $Tot $IP | grep -c "ttl=")     # Probar varias veces y contar cuantas respuestas

  # Con curl (susceptible de ser diferenciable por URL en firewall):
  curl $IP --max-time 10 > nul
  Resp=$?

  VOL=$(cat $COL)                                # Leer el conteo de veces online en estos 10 minutos
  if [ $Resp -eq "0" ]; then                     # Si respondio el curl,
    let VOL++                                    # Incrementarlo
  fi
  echo $VOL > $COL                               # Salvarlo
# echo  $(date "+%H%M") $VOL $Marca >> /tmp/LogConex/debug$Pos

  if [ $Md -eq 0 ]; then                         # Si es una decena de minutos ( :10, :20, :30...),
  echo "0" > $COL                                # resetear el contador de veces online
    case $VOL in                                 # Segun las veces que haya tenido conexion en el periodo
      0)                                         #  Si no se conecto ni una vez
        if [ $M -eq 0 ]; then                    #  Y el minuto es cero, hora en punto,
          Marca=$Np                              #   usar la marca de offline hora en punto
          else                                   #  Si el minuto no es cero
          Marca=$Nn                              #   usar la marca de offline normal
        fi
        ;;
      10)                                        #  Si se conecto las 10 veces
        if [ $M -eq 0 ]; then                    #  Y el minuto es cero, hora en punto,
          Marca=$Sp                              #   usar la marca de online hora en punto
          else                                   #  Si el minuto no es cero
          Marca=$Sn                              #   usar la marca de online normal
        fi
        ;;
      *)                                         #  Entre 1 y 9 veces,
        Marca=$VOL                               #   usar el contador como marca
        ;;
    esac
    Registrar $Marca $Log
# echo  $Marca >> /tmp/LogConex/debug$Pos
  fi
}

Registrar() {
  # Esta subrutina registra el caracter $1 en la fila {FechaDeHoy + 2} y columna {DecenaDeMinutos + 4} del archivo $2
  Car=$1                                     # Usar nombre de variable mas descriptivo
  Arch=$2                                    # Usar nombre de variable mas descriptivo

  H=$(TZ=":America/Caracas" date +'%H')      # Tomar la hora
  M=$(TZ=":America/Caracas" date +'%M')      # Tomar los minutos
  Mm=$((${H#0} * 60 + ${M#0} ))              # Calcular el minuto desde media noche
  Dec=$(($Mm / 10))                          # Calcular la columna de esa decena de minutos
  Fecha=$(TZ=":America/Caracas" date +'%d ') # Tomar la fecha (y el espacio separador de la cuadricula)

  # Uso el script SED en un archivo para evitar conflictos entre la expansion de variables y el regexp
  # Uso "printf" y no "echo" porque parece que el segundo no entiende el \1 dentro de un script
  # Componer el nombre del archivo para el script SED
  Ssed=/tmp/LogConex/$(basename $Arch).sed$(TZ=":America/Caracas" date +'%2d')
  printf "s/(^$Fecha.{$Dec})./\\\1$Car/" > $Ssed
  cat $Arch | sed -E -f $Ssed > /tmp/LogConex/$(basename $Arch)
  cp /tmp/LogConex/$(basename $Arch) $Arch

        # Logica del one-liner para cambiar UN caracter cualquiera
        # Ej que venga despues de 7 careacteres cualesquiera
        # en la linea que comienza por `12 `
        #  +--- muestra en pantalla
        #  |     + ----  el archivo prueba.log
        #  |     |          +--- Stream EDitor
        #  |     |          |   +--- con RegExp
        #  |     |          |   |  +--- sustituyendo
        #  |     |          |   |  |  +---- ^ = ancla de inicio de la linea
        #  |     |          |   |  |  | +----- caracteres "12 "
        #  |     |          |   |  |  |/ \+---- cualquier caracter
        #  |     |          |   |  |  |   | +---- 7 veces
        #  |     |          |   |  |  |   |/  \+--- UN SOLO caracter cualquiera fuera de los () ("." = cualquiera en RegExp)
        #  |     |          |   |  |  |   |    |
        #  |     |          |   |  |  |   |    |
        #  |     |          |   |  |  |   |    |  +---- conservar el primer match (el "12 .......")
        #  |     |          |   |  |  |   |    |  |+------ y sustituirlo por la letra F
        #  |     |          |   |  |  |   |    |  ||
        # cat prueba.log | sed -E 's/(^12 .{7})./\1F/'

  # Actualizar pubicacion cada 10 minutos:
  # El directorio destino es la base de las webs, mas el subdirectorio de los logs
     ${0%/*}/Publicar.sh $Log /Resto/web/logs/index.html
echo ${0%/*}/Publicar.sh $Log /Resto/web/logs/index.html > /tmp/LogConex/debug$Pos    ## DEBUG ##
}

CrearLogMes() {
  # CREAR EL ARCHIVO DE REGISTRO DEL MES,
  #  una cuadricula de 24x6 decenas de minutos X 31 dias del mes mas largo,
  #  mas los encabezados de filas y columnas
  Arch=$1  # path/nombre del archivo
  N=$2     # marca de 'no registrado' normal
  P=$3     # marca de 'no registrado' hora en punto

# LOS TITULOS ENCABEZADOS Y ENCABEZADOS PASARON AL ARCHIVO inihatml PORQUE SON FIJOS
#  ### CREACION DE ENCABEZADOS COMIENZA ###
#  echo "Conexiones desde $(hostname -d) a $IP durante $(LC_TIME="es_VE.UTF-8"  date "+%B %Y")" > $Arch
#  echo -e "\n" >> $Arch
#  echo " * servicio 100% activo | # servicio 100% activo y es hora en punto" >> $Arch
#  echo "1~9 servicio activo 10% ~ 90%" >> $Arch
#  echo " - servicio  0%  activo | + servicio 0% activo y es hora en punto" >> $Arch
#  echo " . no hay registro      | , no hay registro y es hora en punto" >> $Arch
#  echo -e "\n" >> $Arch
#  echo "Fecha" >> $Arch
#  echo " |" >> $Arch
#  echo " V    Decimas de hora -->" >> $Arch
#  ### CREACION DE ENCABEZADOS TERMINA ###
#  ### FILA DE DECENAS DE HORA COMIENZA ###
#  echo -n "   " >> $Arch                                  # Separador del resto de esta fila de encabezado
#  for i in $(seq 0 9); do                                 # Recorrer las primeras 10 horas}
#    echo -n "0     " >> $Arch                             # Las primeras 10 horas empiezan por 0
#  done
#  for i in $(seq 0 9); do                                 # Recorrer las segundas 10 horas
#    echo -n "1     " >> $Arch                             # Las segundas 10 horas empiezan por 1
#  done
#  for i in $(seq 0 3); do                                 # Recorrer las terceras 10 horas
#    echo -n "2     " >> $Arch                             # Las terceras 10 horas empiezan por 2
#  done
#  echo "" >> $Arch                                        # Fin de linea de decenas de horas
#  ### FILA DE DECENAS DE HORA TERMINA ###
#  ### FILA DE UNIDADES  DE HORA COMIENZA ###
#  echo -n "   " >> $Arch                                  # Separador del resto de esta fila de encabezado
#  for i in $(seq 0 9); do                                 # Recorrer las primeras 10 horas
#    echo -n "$i     " >> $Arch                            # agregando cada unidad de hora en punto
#  done
#  for i in $(seq 0 9); do                                 # Recorrer las segundas 10 horas
#    echo -n "$i     " >> $Arch                            # agregando cada unidad de hora en punto
#  done
#  for i in $(seq 0 3); do                                 # Recorrer las terceras 10 horas
#    echo -n "$i     " >> $Arch                            #  agregando cada unidad de hora en punto
#  done
#  echo "" >> $Arch                                        # Fin de linea de unidades de horas
#  ### FILA DE UNIDADES  DE HORA TERMINA ###

  ### 31 FILAS DE CADA FECHA Y 24x6 POSICIONES COMIENZA ###
  for i in $(seq 1 31); do                                # Crear las 31 lineas de dias del mes mas largo
    printf "%02d " $i >> $Arch                            # Inicio de cada linea con printf y no echo para poder preceder ceros o espac$
    for j in $(seq 0 23); do                              # Para cada una de las 24 horas,
      echo -n $P$N$N$N$N$N >> $Arch                       # Crear los placeholders
    done
    echo "" >> $Arch                                      # Fin de linea de esta fecha
  done
  echo "" >> $Arch                                        # Linea separador por legibilidad
  ### 31 FILAS DE CADA FECHA Y 24x6 POSICIONES TERMINA ###
}

# Ahora si, con todas las funciones definidas,
# ejecutar la principal con los argumentos pasados
main "$@"
