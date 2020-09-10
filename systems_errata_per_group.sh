#!/bin/bash
#
# Generador de reportes de patches pendientes por sistema de cada system group de SUSE Manager
#
# Modo de ejecucion:
#  - Para generar reportes de todos los system groups:
#        sudo bash systems_errata_per_group.sh
#  - Para generar reportes de algunos system groups:
#        sudo bash systems_errata_per_group.sh NOMBRE_SYSTEM_GROUP01 NOMBRE_SYSTEM_GROUP02
#

SPACEWALK_REPORT=/usr/bin/spacewalk-report
SYSTEM_GROUPS=$*

#set -x

function print_by_system_group()
{
    SGROUP="$1"

    declare -A patches_needed
    REPORT_FILENAME="system_group_"${SGROUP}"_$(date +%s).csv"

    echo -n "* Generando reporte para el grupo "${SGROUP}"... "
    echo "Servidor,Patches de seguridad pendientes" > "$REPORT_FILENAME"

    for system in $(${SPACEWALK_REPORT} system-groups-systems --where-group_name="${SGROUP}" | awk 'NR > 1' | cut -d, -f3,4);
    do
        server_id=$(echo $system | cut -d, -f1)
        server_name=$(echo $system | cut -d, -f2)

        echo $server_name,$(obtain_patches_needed ${server_id}) >> "$REPORT_FILENAME"
    done

   echo "[HECHO]"
   echo "  * Archivo del reporte: ${REPORT_FILENAME}"
}

function obtain_patches_needed()
{
    SYSTEM_ID=$1

    sum=0
    IFS=$' '
    for num in $(${SPACEWALK_REPORT} system-currency --where-system_id=${SYSTEM_ID} | awk 'NR > 1' | cut -d, -f4,5,6,7 | tr ',' ' ');
    do
        sum=$(($sum + $num));
    done

    echo $sum
}

function print_all_system_groups()
{
    IFS=$'\n'
    for group in $(${SPACEWALK_REPORT} system-groups | awk 'NR > 1' | cut -d, -f2);
    do
        print_by_system_group "$group"
    done
}

if [ -z "${SYSTEM_GROUPS}" ];
then
    print_all_system_groups
else
    for group in "${SYSTEM_GROUPS}";
    do
       print_by_system_group "${group}"
    done
fi
