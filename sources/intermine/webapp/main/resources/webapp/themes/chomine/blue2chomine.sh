#!/bin/bash

#------------------------------------------------------------------------
# change val to valide imageMagick modulate hue value [between 1 and 200]
#------------------------------------------------------------------------

if [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -gt 0 -a "$1" -lt 201 ]
then
    val=$1
else
    echo "$0: hue value is not between 1 and 200."
    echo "Set to default: 125"
    val=125
fi

#------------------
# change png images
#------------------

cp -r ../blue/* .
for i in *.png
do
    convert -modulate 100,100,$val $i $i
done
cp ../blue/xml.png .

cd report
for i in *.png
do
    convert -modulate 100,100,$val $i $i
done
cd ..

cd homepage
for i in *.png
do
    convert -modulate 100,100,$val $i $i
done
cd ..

#-----------------
# change theme.css
#-----------------

perl convertBlueTheme2chomine.pl -m $val > temp.css
mv temp.css theme.css
