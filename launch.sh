#!/bin/bash

# Optimize OpenMP performance behaviour
export OMP_SCHEDULE=static  # Disable dynamic loop scheduling
export OMP_PROC_BIND=TRUE   # Bind threads to specific resources
export OMP_DYNAMIC=false    # Disable dynamic thread pool sizing

echo -e "Thread\tBandwidth\tAvgTime\tMinTime\tMaxTime" >& `hostname`"_copy.csv"
echo -e "Thread\tBandwidth\tAvgTime\tMinTime\tMaxTime" >& `hostname`"_scale.csv"
echo -e "Thread\tBandwidth\tAvgTime\tMinTime\tMaxTime" >& `hostname`"_add.csv"
echo -e "Thread\tBandwidth\tAvgTime\tMinTime\tMaxTime" >& `hostname`"_triad.csv"

num_pu=$(grep -c "^processor" /proc/cpuinfo)
for i in `seq 1 $num_pu`
do

export OMP_PLACES={0:$i:1}
export OMP_NUM_THREADS=$i


# Fichier d'entrée
fichier=`hostname`"_stream_$i.log"

# Running stream
./stream_c.exe >& $fichier 

# Initialiser des tableaux associatifs pour chaque mot-clé (Bash 4+)
declare -A Copy
declare -A Scale
declare -A Add
declare -A Triad

# Lire le fichier ligne par ligne
while IFS= read -r ligne; do
    # Vérifier si la ligne contient un des mots-clés
    if [[ "$ligne" =~ ^(Copy|Scale|Add|Triad): ]]; then
        mot_cle="${BASH_REMATCH[1]}"

        # Extraire les valeurs numériques avec awk
        valeurs=($(echo "$ligne" | awk '{for(i=1; i<=NF; i++) if($i ~ /^[0-9]+\.[0-9]+$/) print $i}'))

        # Stocker les valeurs dans le tableau associatif correspondant
        eval "$mot_cle=([val1]=\"${valeurs[0]}\" [val2]=\"${valeurs[1]}\" [val3]=\"${valeurs[2]}\" [val4]=\"${valeurs[3]}\")"
    fi
done < "$fichier"

# Afficher les résultats
echo -e "$i\t${Copy[val1]}\t${Copy[val2]}\t${Copy[val3]}\t${Copy[val4]}" >> `hostname`"_copy.csv"
echo -e "$i\t${Scale[val1]}\t${Scale[val2]}\t${Scale[val3]}\t${Scale[val4]}" >> `hostname`"_scale.csv"
echo -e "$i\t${Add[val1]}\t${Add[val2]}\t${Add[val3]}\t${Add[val4]}" >> `hostname`"_add.csv"
echo -e "$i\t${Triad[val1]}\t${Triad[val2]}\t${Triad[val3]}\t${Triad[val4]}" >> `hostname`"_triad.csv"

done
