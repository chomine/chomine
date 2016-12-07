#!/bin/bash
mkdir -p single
mkdir -p data

echo "1. download cge pathway map titles"
wget http://rest.kegg.jp/list/pathway/cge -O data/map_title.tab > log 2> err
sed -i 's/^path://' data/map_title.tab

echo "2. download single pathways"
while read l; do
    map=$(echo $l | awk '{print $1}')
    echo "$map" >> log 2>> err
    wget http://rest.kegg.jp/get/path:$map -O single/$map >> log 2>> err
done < data/map_title.tab

cat single/* > all_maps.tab
