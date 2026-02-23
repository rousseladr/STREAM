#!/bin/bash

# Initialiser la taille totale à 0
total_l3_bytes=0
# Liste pour stocker les IDs de cache L3 déjà traités
declare -A processed_cache_ids

# Parcourir chaque cache (pas chaque CPU)
for cache_path in /sys/devices/system/cpu/cpu*/cache/index*/; do
    # Vérifier si le cache est de niveau 3
    if grep -q "^3$" "$cache_path/level"; then
        # Récupérer l'ID unique du cache
        cache_id=$(cat "$cache_path/id")
        # Vérifier si cet ID a déjà été traité
        if [[ -z "${processed_cache_ids[$cache_id]}" ]]; then
            # Marquer cet ID comme traité
            processed_cache_ids["$cache_id"]=1
            # Récupérer la taille du cache (ex: "32768K")
            size_with_unit=$(cat "$cache_path/size")
            # Extraire uniquement la valeur numérique
            size_kb=$(echo "$size_with_unit" | sed 's/K//')
            # Convertir en octets
            size_bytes=$((size_kb * 1024))
            # Ajouter à la taille totale
            total_l3_bytes=$((total_l3_bytes + size_bytes))
        fi
    fi
done

# Afficher le résultat
#echo "Taille totale des caches L3 (sans double comptage) : $total_l3_bytes octets"

# Optional : Convert to MiB
#total_l3_mib=$(echo "scale=2; $total_l3_bytes / (1024 * 1024)" | bc)
#echo "Taille totale des caches L3 : $total_l3_mib MiB"

l3_size_value="$total_l3_bytes"

dn=$(echo "$l3_size_value * 3.8 / 7.5" | bc)

# Round up to the nearest ten
dn=$(echo "($dn + 9) / 10 * 10" | bc)

# Setting in bytes
#dn=$(echo "$dn * 10^6" | bc)

# Print results
echo "DSTREAM_ARRAY_SIZE=$dn"
