#!/bin/bash

################################################################################
#
# AUTHOR
#
# Matthias P. Gerstl (matthias.gerstl@acib.at)
#
#
# README
#
# Do not change anything here if you do not know what you are doing!
#
################################################################################

#=======================
# find current directory
#=======================
pwd=$(pwd)

#====================
# read configurations
#====================
source "$pwd/config"

#========================
# set working directories
#========================
pwd=$(pwd)
if [[ $different_data_dir != true ]]; then
    datadir="$pwd/data"
fi
if [[ $different_dump_dir != true ]]; then
    dumpdir="$pwd/db_dump"
fi
logdir="$pwd/log"

#==================================
# define number of steps to perform
#==================================
steps=38
if [[ $build_webapp == true ]]; then
    steps=$((steps + 1))
fi
count=0

#==========
# functions
#==========
function getTime {
  date +"%Y-%m-%d %H:%M:%S" 
}

function checkError {
  t=$(wc -l "$1" | awk '{print $1}')
  if (( t > 0 ))
  then
      echo FAILED
      echo " "
  fi
}

function checkException {
  t=$(grep -c Exception "$1")
  if (( t > 0 ))
  then
      echo FAILED: "$1" threw Exception
      msg=$(grep Exception "$1")
      echo "$msg"
      echo " "
  fi
}

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): prepare directories"
#===============================================================================
mkdir -p ~/.intermine
mkdir -p "$datadir/genome/brinkrolf/gff"
mkdir -p "$datadir/genome/brinkrolf/fasta"
mkdir -p "$datadir/genome/brinkrolf/go-annotation"
mkdir -p "$datadir/genome/lewis/gff"
mkdir -p "$datadir/genome/lewis/fasta"
mkdir -p "$datadir/genome/xu/gff"
mkdir -p "$datadir/genome/xu/fasta"
mkdir -p "$datadir/genome/uniprot_merge"
mkdir -p "$datadir/mirbase"
mkdir -p "$datadir/uniprot"
mkdir -p "$datadir/interpro"
mkdir -p "$datadir/ontology"
mkdir -p "$datadir/kegg/data"
mkdir -p "$datadir/pubmed"
mkdir -p "$datadir/sbml"
mkdir -p "$dumpdir"
mkdir -p "$logdir"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): get intermine"
#===============================================================================
len=${#intermine_folder}
if (( len < 1 ))
then
    git clone https://github.com/intermine/intermine.git "$pwd/intermine"
else
    cp -r "$intermine_folder" "$pwd/intermine"
fi

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): change to set intermine tag"
#===============================================================================
cd "$pwd/intermine"
git checkout -b chomine "$intermine_tag"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): check bug in PostProcessorTask"
#===============================================================================
cd "$pwd"
d=$(diff "$pwd/comparisons/PostProcessorTask.java" \
    "$pwd/intermine/intermine/integrate/main/src/org/intermine/task/PostProcessorTask.java" \
    | wc -l)
if (( d > 0 ))
then
    echo "PostProcessorTask.java has changed in this intermine version."
    echo "Please verify"
    echo "Stop script now"
    exit
fi

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): prepare annotation for Brinkrolf sequencing"
#===============================================================================
perl "$pwd/scripts/sortGffFile.pl" -i "$brinkrolf_gff" -o "$pwd/temp.gff"
perl "$pwd/scripts/setIds.pl" -i "$pwd/temp.gff" \
    -o "$datadir/genome/brinkrolf/gff/annotations_brinkrolf.gff"
rm "$pwd/temp.gff"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): prepare annotation for Lewis sequencing"
#===============================================================================
perl "$pwd/scripts/sortLewisXuGffFile.pl" -i "$lewis_gff" \
    -o "$datadir/genome/lewis/gff/annotations_lewis.gff"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): prepare annotation for Xu sequencing"
#===============================================================================
perl "$pwd/scripts/sortLewisXuGffFile.pl" -i "$xu_gff" \
    -o "$datadir/genome/xu/gff/annotations_xu.gff"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): parse GO annotion out of Brinkrolf sequencing"
#===============================================================================
perl "$pwd/scripts/createGoAnnotationFile.pl" \
    -i "$datadir/genome/brinkrolf/gff/annotations_brinkrolf.gff" \
    -o "$datadir/genome/brinkrolf/go-annotation/gene_association.brinkrolf"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): prepare uniprot gff merge file"
#===============================================================================
trembl=$uniprot_folder/10029_uniprot_trembl.xml
perl "$pwd/scripts/create_uniprot_gff_merge.pl" \
    -g "$datadir/genome/brinkrolf/gff/annotations_brinkrolf.gff" \
    -u "$trembl" \
    -o "$pwd/temp_a"
perl "$pwd/scripts/create_uniprot_lewis_xu_gff_merge.pl" \
    -g "$datadir/genome/lewis/gff/annotations_lewis.gff" \
    -u "$trembl" \
    -p lewis \
    -o "$pwd/temp_b"
perl "$pwd/scripts/create_uniprot_lewis_xu_gff_merge.pl" \
    -g "$datadir/genome/xu/gff/annotations_xu.gff" \
    -u "$trembl" \
    -p xu \
    -o "$pwd/temp_c"
cat "$pwd/temp_a" "$pwd/temp_b" "$pwd/temp_c" > "$datadir/genome/uniprot_merge/uniprot.merge"
rm "$pwd/temp_a" "$pwd/temp_b" "$pwd/temp_c"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): copy brinkrolf fasta file"
#===============================================================================
cp "$brinkrolf_fa" "$datadir/genome/brinkrolf/fasta/"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): copy lewis fasta file"
#===============================================================================
cp "$lewis_fa" "$datadir/genome/lewis/fasta/"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): copy xu fasta file"
#===============================================================================
cp "$xu_fa" "$datadir/genome/xu/fasta/"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): copy SBML files"
cp "$sbml_folder/"* "$datadir/sbml"
#===============================================================================

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): copy miRBase data"
#===============================================================================
cp "$mirna_file" "$datadir/mirbase/"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): copy uniprot data"
#===============================================================================
cp "$uniprot_folder/10029_uniprot_sprot.xml" "$datadir/uniprot/"
cp "$uniprot_folder/10029_uniprot_trembl.xml" "$datadir/uniprot/"
cp "$uniprot_folder/keywlist.xml" "$datadir/uniprot/"
cp "$uniprot_folder/uniprot_sprot_varsplic.fasta" "$datadir/uniprot/"
cp "$uniprot_folder/dbxref.txt" "$datadir/uniprot/"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): copy interpro data"
#===============================================================================
cp "$interpro_folder/interpro.xml" "$datadir/interpro/"
cp "$interpro_folder/protein2ipr.dat" "$datadir/interpro/"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): copy ontology data"
#===============================================================================
cp "$so_folder/so-xp.obo" "$datadir/ontology/"
cp "$go_folder/gene_ontology.obo" "$datadir/ontology/"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): copy pubmed data"
#===============================================================================
cp "$pubmed_folder/gene2pubmed" "$datadir/pubmed/"
cp "$pubmed_folder/gene_info" "$datadir/pubmed/"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): get kegg data"
#===============================================================================
lenA=${#kegg_gene_map}
lenB=${#kegg_path_map}
if (( "$lenA" < 1 )) || (( "$lenB" < 1 )) 
then
    cd "$datadir/kegg"
    lewis_file=$(ls -1 "$datadir/genome/lewis/gff/"*".gff")
    xu_file=$(ls -1 "$datadir/genome/xu/gff/"*".gff")
    bash "$pwd/scripts/getKeggPathwayMaps.sh"
    perl "$pwd/scripts/createKeggIntermineInputFile.pl" \
        -i all_maps.tab \
        -l "$lewis_file" \
        -x "$xu_file" \
        -u "$datadir/uniprot/10029_uniprot_trembl.xml" \
        > "$datadir/kegg/data/cge_gene_map.tab"
else
    cp "$kegg_gene_map" "$datadir/kegg/data/cge_gene_map.tab"
    cp "$kegg_path_map" "$datadir/kegg/data/map_title.tab"
fi

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): change directory"
#===============================================================================
cd "$pwd/intermine"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): create ChoMine"
#===============================================================================
perl "$pwd/intermine/bio/scripts/make_mine" ChoMine

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): copy properties to properties folder"
#===============================================================================
cp "$pwd/sources/chomine.properties" ~/.intermine/

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): copy intermine/intermine folder"
#===============================================================================
cp -r "$pwd/sources/intermine" "$pwd/intermine/"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): copy intermine/bio folder"
#===============================================================================
cp -r "$pwd/sources/bio" "$pwd/intermine/"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): copy intermine/chomine folder"
#===============================================================================
cp -r "$pwd/sources/chomine" "$pwd/intermine/"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): update project.xml"
#===============================================================================
repl=${datadir//\//\\\/}
sed -i "s/DATADIR/$repl/g" "$pwd/intermine/chomine/project.xml"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): correct gff properties for ChoMine"
#===============================================================================
t_file=$pwd/intermine/bio/core/main/resources/gff_config.properties
echo " " >> "$t_file"
echo "10029.excludes=region,cDNA_match,match" >> "$t_file"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): correct kegg properties for ChoMine"
#===============================================================================
t_file=$pwd/intermine/bio/sources/kegg-pathway/main/resources/kegg_config.properties
echo -e " 
# chinese hamster
cge.taxonId = 10029
cge.identifier = primaryIdentifier" >> "$t_file"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): build database"
#===============================================================================
cd "$pwd/intermine/chomine/dbmodel"
logprefix=$logdir/dbmodel-clean
ant clean-all > "$logprefix.log" 2> "$logprefix.err"
checkError "$logprefix.err"
checkException "$logprefix.log"
logprefix=$logdir/build-db
ant build-db > "$logprefix.log" 2> "$logprefix.err"
checkError "$logprefix.err"
checkException "$logprefix.log"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): integrate data"
#===============================================================================
cd "$pwd/intermine/chomine/integrate"
logprefix=$logdir/integrate-clean
ant clean > "$logprefix.log" 2> "$logprefix.err"
checkError "$logprefix.err"
checkException "$logprefix.log"
total=$(grep -c "<source " ../project.xml)
sources=$(grep "<source " ../project.xml | awk -F '"' '{print $2}')
mycount=0
for i in $sources
do
    mycount=$((mycount + 1))
    logprefix=$logdir/$i
    echo "    $mycount/$total ($(getTime)): integrate $i"
    ant -Dsource="$i" > "$logprefix.log" 2> "$logprefix.err"
    checkError "$logprefix.err"
    checkException "$logprefix.log"
done

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): dump database before postprocess"
#===============================================================================
cd "$dumpdir"
export PGPASSWORD=$db_password; \
    pg_dump --no-owner --no-acl -h "$db_host" -p "$db_port" -U "$db_user" \
    -Fc "$db_mine" > "$db_mine"".beforepp.db"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): postprocess"
#===============================================================================
cd "$pwd/intermine/chomine/postprocess"
logprefix=$logdir/postprocess-clean
ant clean > "$logprefix.log" 2> "$logprefix.err"
total=$(grep -c "<post-process " ../project.xml)
sources=$(grep "<post-process " ../project.xml | awk -F '"' '{print $2}')
mycount=0
for i in $sources
do
    if [[ $i == "do-sources" ]]
    then
        export PGPASSWORD=$db_password; \
            pg_dump --no-owner --no-acl -h "$db_host" -p "$db_port" -U "$db_user" \
            -Fc "$db_mine" > "$dumpdir/$db_mine"".before_do-sources.db"
    fi
    mycount=$((mycount + 1))
    logprefix=$logdir/$i
    echo "    $mycount/$total ($(getTime)): perform postprocess $i"
    ant -Daction="$i" > "$logprefix.log" 2> "$logprefix.err"
    checkError "$logprefix.err"
    checkException "$logprefix.log"
done

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): build userprofile db"
#===============================================================================
cd "$pwd/intermine/chomine/webapp"
logprefix=$logdir/webapp-clean
ant clean > "$logprefix.log" 2> "$logprefix.err"
checkError "$logprefix.err"
checkException "$logprefix.log"
logprefix=$logdir/build-db-userprofile
ant build-db-userprofile > "$logprefix.log" 2> "$logprefix.err"
checkError "$logprefix.err"
checkException "$logprefix.log"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): precompute queries"
#===============================================================================
cd "$pwd/intermine/chomine/webapp"
logprefix=$logdir/precompute-queries
ant precompute-queries > "$logprefix.log" 2> "$logprefix.err"
checkError "$logprefix.err"
checkException "$logprefix.log"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): precompute templates"
#===============================================================================
cd "$pwd/intermine/chomine/webapp"
logprefix=$logdir/precompute-templates
ant precompute-templates > "$logprefix.log" 2> "$logprefix.err"
checkError "$logprefix.err"
checkException "$logprefix.log"

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): dump databases"
#===============================================================================
cd "$dumpdir"
export PGPASSWORD=$db_password; \
    pg_dump --no-owner --no-acl -h "$db_host" -p "$db_port" -U "$db_user" \
    -Fc "$db_mine" > "$db_mine"".db"
export PGPASSWORD=$db_password; \
    pg_dump --no-owner --no-acl -h "$db_host" -p "$db_port" -U "$db_user" \
    -Fc "$db_items" > "$db_items"".db"
export PGPASSWORD=$db_password; \
    pg_dump --no-owner --no-acl -h "$db_host" -p "$db_port" -U "$db_user" \
    -Fc "$db_userprofile" > "$db_userprofile"".db"
md5sum ./*.db > db.md5sum

if [[ $build_webapp == true ]]; then
    #===============================================================================
    count=$((count + 1))
    echo "$count/$steps ($(getTime)): build webapp"
    #===============================================================================
    cd "$pwd/intermine/chomine/webapp"
    logprefix=$logdir/webapp-default
    ant default > "$logprefix.log" 2> "$logprefix.err"
    checkError "$logprefix.err"
    checkException "$logprefix.log"
    logprefix=$logdir/remove-webapp
    ant remove-webapp > "$logprefix.log" 2> "$logprefix.err"
    checkError "$logprefix.err"
    checkException "$logprefix.log"
    logprefix=$logdir/release-webapp
    ant release-webapp > "$logprefix.log" 2> "$logprefix.err"
    checkError "$logprefix.err"
    checkException "$logprefix.log"
fi

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): clean up"
#===============================================================================
if [[ $keep_sources == false ]]; then
    rm -rf "$datadir"
else
    if [[ $compress_sources == true ]]; then
        cd "$datadir"
        dirs=$(find . -type f -exec dirname {} \; | uniq)
        for i in $dirs
        do
            cd "$i"
            find . -maxdepth 1 -type f -exec gzip {} \;
            md5sum ./*.gz > md5
            cd "$datadir"
        done
    fi
fi
if [[ $keep_intermine_logs == false ]]; then
    cd "$pwd/intermine/chomine/dbmodel"
    rm -f intermine.log*
    cd "$pwd/intermine/chomine/integrate"
    rm -f intermine.log*
    cd "$pwd/intermine/chomine/postprocess"
    rm -f intermine.log*
    cd "$pwd/intermine/chomine/webapp"
    rm -f intermine.log*
else
    if [[ $compress_intermine_logs == true ]]; then
        cd "$pwd/intermine/chomine/dbmodel"
        tar czf intermine.log.tar.gz intermine.log*
        rm -f intermine.log intermine.log.? intermine.log.??
        cd "$pwd/intermine/chomine/integrate"
        tar czf intermine.log.tar.gz intermine.log*
        rm -f intermine.log intermine.log.? intermine.log.??
        cd "$pwd/intermine/chomine/postprocess"
        tar czf intermine.log.tar.gz intermine.log*
        rm -f intermine.log intermine.log.? intermine.log.??
        cd "$pwd/intermine/chomine/webapp"
        tar czf intermine.log.tar.gz intermine.log*
        rm -f intermine.log intermine.log.? intermine.log.??
    fi
fi
if [[ $keep_git_repository == false ]]; then
    cd "$pwd/intermine"
    rm -rf .git
    find . -name .gitignore -exec rm -f {} \;
    cd "$pwd"
fi

#===============================================================================
count=$((count + 1))
echo "$count/$steps ($(getTime)): finished"
#===============================================================================
cd "$pwd"

