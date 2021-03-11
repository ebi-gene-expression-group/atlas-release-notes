#!/usr/bin/env bash

usage() { echo "Usage: $0 [-d <release date in +%Y-%m-%d, can also be supplied in env var RELEASE_DATE, guessed from current date if not set>] [-r <release number, can also be supplied in env var RELEASE_NUMBER, guessed from last release if not set>] [-p <previous release date to compare to, in +%Y-%m-%d, can also be supplied in env var PREVIOUS_RELEASE_DATE, guessed from last release if not set>] -a <atlas sc experiments dir, defaults to value of ATLAS_SC_EXPERIMENTS if set>" 1>&2; }

# Parse arguments

releaseDate=${RELEASE_DATE:-''}
releaseDate=${releaseDate:-$(date "+%Y-%m-%d")}
releaseNumber=${RELEASE_NUMBER:-''}
previousReleaseDate=${PREVIOUS_RELEASE_DATE:-''}
atlasScExperimentsDir=${ATLAS_SC_EXPERIMENTS:-''}

while getopts ":d:r:p:a:" o; do
    case "${o}" in
        d)
            releaseDate=${OPTARG}
            ;;
        r)
            releaseNumber=${OPTARG}
            ;;
        p)
            previousReleaseDate=${OPTARG}
            ;;
        a)
            atlasScExperimentsDir=${OPTARG}
            ;;
        *)
            usage
            exit 0
            ;;
    esac
done
shift $((OPTIND-1))

# Guess release number from last release

if [ -z "$releaseNumber" ]; then
    lastRelease=$(ls release-notes/sc/_posts/ | sed 's/.md//' | awk -F'-' '{print $4}' | sort -nr | head -n 1)
    releaseNumber=$(($lastRelease + 1))
fi

releaseNotesFile="release-notes/sc/_posts/${releaseDate}-${releaseNumber}.md"
echo "Will write new release notes to release-notes/sc/_posts/${releaseDate}-${releaseNumber}.md"

if [ -z "$atlasScExperimentsDir" ]; then
    echo "You need to supply the path to the Atlas SC experiments dir vi -a, or the ATLAS_SC_EXPERIMENTS environment variable." 1>&2
    exit 1
fi

raw_cells=$(printf "%'.f" $(cat $atlasScExperimentsDir/cell_stats.json | jq '.raw_cells'))
filtered_cells=$(printf "%'.f" $(cat $atlasScExperimentsDir/cell_stats.json | jq '.filtered_cells'))
all_species=`curl -s https://wwwdev.ebi.ac.uk/gxa/sc/json/experiments | jq '.experiments | .[].species' | sort -u`
n_species=$(echo -e "$all_species" | tr '[:upper:]' '[:lower:]' | sort -u | wc -l)
n_studies=$(curl -s https://wwwdev.ebi.ac.uk/gxa/sc/json/experiments | jq '.experiments | map(select(.rawExperimentType | test("(BASELINE)"; "i"))) | length')

# Guess last release date if not provided

if [ -n "$previousReleaseDate" ]; then
    last_release_epoch_time=$(echo $previousReleaseDate | awk -F'-' '{ print $2"/"$3"/"$1}' | while read -r l; do date "+%s" -d "$l"; done | sort -nr | head -n 1)
else
    last_release_epoch_time=$(ls -t release-notes/sc/_posts/ | sed 's/.md//' | awk -F'-' '{print $2"/"$3"/"$1}' | while read -r l; do date "+%s" -d "$l"; done | sort -nr | head -n 1)
fi

# Replace wildcards in stats with auto-derived versions

cat sc_helper/release_notes_templates/data_statistics.md | \
    sed "s/N_STUDIES/$n_studies/" | sed "s/N_CELLS/$raw_cells/" | sed "s/N_CELLS_QC/$filtered_cells/" | sed "s/N_SPECIES/$n_species/" > $releaseNotesFile

# Do some automated subsitutions on stats here!

echo -e "\n#### New experiments" >> $releaseNotesFile

curl 'https://wwwdev.ebi.ac.uk/gxa/sc/json/experiments' | 
    jq -r '.experiments | .[] | select(.lastUpdate | strptime("%d-%m-%Y") | mktime > '$last_release_epoch_time') | [.experimentAccession, .experimentDescription] | @csv' | \
    awk -v FS="," '{ printf "- [%s](https://www.ebi.ac.uk/gxa/sc/experiments/%s)\n", $2, $1}' | sed s/\"//g >> $releaseNotesFile

echo -e "\n#### New features" >> $releaseNotesFile


