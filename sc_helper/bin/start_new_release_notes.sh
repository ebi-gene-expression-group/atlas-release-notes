#!/usr/bin/env bash

releaseDate=${1:-$(date "+%Y-%m-%d")}
releaseNumber=${2}

if [ -z "$releaseNumber" ]; then
    lastRelease=$(ls release-notes/sc/_posts/ | sed 's/.md//' | awk -F'-' '{print $4}' | sort -nr | head -n 1)
    releaseNumber=$(($lastRelease + 1))
fi

releaseNotesFile="release-notes/sc/_posts/${releaseDate}-${releaseNumber}.md"
echo "Will write new release notes to release-notes/sc/_posts/${releaseDate}-${releaseNumber}.md"

if [ -z "$ATLAS_SC_EXPERIMENTS" ]; then
    echo "You need to set ATLAS_SC_EXPERIMENTS" 1>&2
    exit 1
fi

raw_cells=$(printf "%'.f" $(cat $ATLAS_SC_EXPERIMENTS/cell_stats.json | jq '.raw_cells'))
filtered_cells=$(printf "%'.f" $(cat $ATLAS_SC_EXPERIMENTS/cell_stats.json | jq '.filtered_cells'))
all_species=`curl -s https://wwwdev.ebi.ac.uk/gxa/sc/json/experiments | jq '.experiments | .[].species' | sort -u`
n_species=$(echo -e "$all_species" | wc -l)
n_studies=$(curl -s https://wwwdev.ebi.ac.uk/gxa/sc/json/experiments | jq '.experiments | map(select(.rawExperimentType | test("(BASELINE)"; "i"))) | length')
last_release_epoch_time=$(ls -t release-notes/sc/_posts/ | sed 's/.md//' | awk -F'-' '{print $2"/"$3"/"$1}' | while read -r l; do date "+%s" -d "$l"; done | sort -nr | head -n 1)

# Replace wildcards in stats with auto-derived versions

cat sc_helper/release_notes_templates/data_statistics.md | \
    sed "s/N_STUDIES/$n_studies/" | sed "s/N_CELLS/$raw_cells/" | sed "s/N_CELLS_QC/$filtered_cells/" | sed "s/N_SPECIES/$n_species/" \
    > $releaseNotesFile

# Do some automated subsitutions on stats here!

echo -e "$stats" > $releaseNotesFile

echo -e "\n#### New experiments" >> $releaseNotesFile

curl 'https://wwwdev.ebi.ac.uk/gxa/sc/json/experiments' | 
    jq -r '.experiments | .[] | select(.lastUpdate | strptime("%d-%m-%Y") | mktime > '$last_release_epoch_time') | [.experimentAccession, .experimentDescription] | @csv' | \
    awk -v FS="," '{ printf "- [%s](https://www.ebi.ac.uk/gxa/sc/experiments/%s)\n", $2, $1}' | sed s/\"//g >> $releaseNotesFile

echo -e "\n#### New features" >> $releaseNotesFile



