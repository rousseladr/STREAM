#!/bin/bash
# Load STREAM built with AOCC
# NOTE: if you have compiled multiple versions you may need to be more specific
# Spack will complain if your request is ambiguous and could refer to multiple
# packages. (https://spack.readthedocs.io/en/latest/basic_usage.html#ambiguous-specs)
#spack load stream %aocc

# For optimal stream performance, it is recommended to set the following OS parameters (requires root/sudo access)
#echo always > /sys/kernel/mm/transparent_hugepage/enabled     # Enable hugepages
#echo always > /sys/kernel/mm/transparent_hugepage/defrag     # Enable hugepages
#echo 3 > /proc/sys/vm/drop_caches                            # Clear caches to maximize available RAM
#echo 1 > /proc/sys/vm/compact_memory                         # Rearrange RAM usage to maximise the size of free blocks

# Optimize OpenMP performance behaviour
export OMP_SCHEDULE=static  # Disable dynamic loop scheduling
export OMP_PROC_BIND=TRUE   # Bind threads to specific resources
export OMP_DYNAMIC=false    # Disable dynamic thread pool sizing

# OMP_PLACES is used for binding OpenMP threads to cores
# See: https://www.openmp.org/spec-html/5.0/openmpse53.html

############# FOR AMD EPYC™ 9654 ##################
# For example, a dual socket AMD 4th Gen EPYC™ Processor with 192 (96x2) cores,
# with 4 threads per L3 cache: 96 total places, stride by 2 cores:

echo -e "Thread\tBandwidth\tAvgTime\tMinTime\tMaxTime" >& `hostname`"_copy.csv"
echo -e "Thread\tBandwidth\tAvgTime\tMinTime\tMaxTime" >& `hostname`"_scale.csv"
echo -e "Thread\tBandwidth\tAvgTime\tMinTime\tMaxTime" >& `hostname`"_add.csv"
echo -e "Thread\tBandwidth\tAvgTime\tMinTime\tMaxTime" >& `hostname`"_triad.csv"

for i in `seq 1 288`
do

export OMP_PLACES={0:$i:1}
export OMP_NUM_THREADS=$i

############# FOR AMD EPYC™ 9755 ##################
# For example, a dual socket AMD 5th Gen EPYC™ Processor with 256 (128x2) cores,
# with 1 thread per L3 cache: 32 total places, stride by 8 cores:
#export OMP_PLACES=0:32:8
#export OMP_NUM_THREADS=32

# Fichier d'entrée (remplace par ton fichier ou utilise une entrée directe)
fichier=`hostname`"_stream_$i.log"

# Running stream
../stream_c.exe >& $fichier 

#ligne_copy = `cat stream_$i.log | grep Copy` 
#ligne_scale = `cat stream_$i.log | grep Scale` 
#ligne_add = `cat stream_$i.log | grep Add` 
#ligne_triad = `cat stream_$i.log | grep Triad` 
#
#read -r _ val1 val2 val3 val4 <<< $(echo "$ligne" | awk '{print $2, $3, $4, $5}')


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
