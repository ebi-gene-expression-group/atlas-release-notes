#!/usr/bin/env bash



releaseDate=${RELEASE_DATE:-''}
releaseDate=${releaseDate:-$(date "+%Y-%m-%d")}
releaseNumber=${RELEASE_NUMBER:-''}
previousReleaseDate=${PREVIOUS_RELEASE_DATE:-''}


while getopts ":d:r:p:" o; do
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
        *)
            usage
            exit 0
            ;;
    esac
done
shift $((OPTIND-1))

# Guess release number from last release
if [ -z "$releaseNumber" ]; then
    lastRelease=$(ls release-notes/gxa/_posts/ | sed 's/.md//' | awk -F'-' '{print $4}' | sort -nr | head -n 1)
    releaseNumber=$(($lastRelease + 1))
fi

# Guess last release date if not provided
if [ -n "$previousReleaseDate" ]; then
    last_release_epoch_time=$(echo $previousReleaseDate | awk -F'-' '{ print $2"/"$3"/"$1}' | while read -r l; do date "+%s" -d "$l"; done | sort -nr | head -n 1)
else
    last_release_epoch_time=$(ls -t release-notes/gxa/_posts/ | sed 's/.md//' | awk -F'-' '{print $2"/"$3"/"$1}' | while read -r l; do date "+%s" -d "$l"; done | sort -nr | head -n 1)
fi

releaseNotesFile="release-notes/gxa/_posts/${releaseDate}-${releaseNumber}.md"
echo "Will write new release notes to $releaseNotesFile"

#Number of experiments
n_studies=$(curl -s https://wwwdev.ebi.ac.uk/gxa/json/experiments | jq '.experiments | length')

#Number of assays
n_assays=$(curl -s https://wwwdev.ebi.ac.uk/gxa/json/experiments | jq '.experiments | map(.numberOfAssays) | add')

#Number of RNA-Seq experiments
n_rnaseq=$(curl -s https://wwwdev.ebi.ac.uk/gxa/json/experiments | jq '.experiments | map(select(.rawExperimentType | test("RNASEQ"; "i"))) | length')

#Number of proteomics experiments
n_prot=$(curl -s https://wwwdev.ebi.ac.uk/gxa/json/experiments | jq '.experiments | map(select(.rawExperimentType | test("PROTEOMICS"; "i"))) | length')

#Number of baseline experiments
n_baseline=$(curl -s https://wwwdev.ebi.ac.uk/gxa/json/experiments | jq '.experiments | map(select(.rawExperimentType | test("BASELINE"; "i"))) | length')

#Number of species in baseline experiments
#Be aware that groups (e.g. Musa acuminata AAA Group) should be collapsed into a single species, whereas subspecies should be considered different ones.
n_baseline_species=$(curl -s https://wwwdev.ebi.ac.uk/gxa/json/experiments | jq '.experiments | map(select(.rawExperimentType | test("BASELINE"; "i"))) | map(.species) | unique | length')

#Number of plants experiments
n_plants=$(curl -s https://wwwdev.ebi.ac.uk/gxa/json/experiments | jq '.experiments | map(select(.kingdom=="plants")) | length')

#Number of differential experiments
n_differential=$(curl -s https://wwwdev.ebi.ac.uk/gxa/json/experiments | jq '.experiments | map(select(.rawExperimentType | test("(MICROARRAY)|(DIFFERENTIAL)"; "i"))) | length')

#Number of comparisons
n_differential_samples=$(curl -s https://wwwdev.ebi.ac.uk/gxa/json/experiments | jq '.experiments | map(select(.rawExperimentType | test("(MICROARRAY)|(DIFFERENTIAL)"; "i"))) | map(.numberOfContrasts) | add')

#Number of species in differential experiments
#Subspecies and varieties (e.g. Brassica rapa subsp. oleifera or Brassica oleracea var. capitata) should count as different species.
n_differential_species=$(curl -s https://wwwdev.ebi.ac.uk/gxa/json/experiments | jq '.experiments | map(select(.rawExperimentType | test("(MICROARRAY)|(DIFFERENTIAL)"; "i"))) | map(.species) | unique | length')

#Number of species in GXA
n_species=$(curl -s https://wwwdev.ebi.ac.uk/gxa/json/experiments | jq '.experiments | map(select(.rawExperimentType | test("(MICROARRAY)|(DIFFERENTIAL)|(BASELINE)"; "i"))) | map(.species) | unique | length')

# Replace wildcards in stats with auto-derived versions
cat gxa_helper/release_notes_templates/gxa_data_statistics.md | \
    sed "s/N_STUDIES/$n_studies/" | sed "s/N_ASSAYS/$n_assays/" | sed "s/N_RNASEQ/$n_rnaseq/" | sed "s/N_PROT/$n_prot/" \
    | sed "s/N_BASELINE/$n_baseline/" | sed "s/N_BASE_SPECIES/$n_baseline_species/g" | sed "s/N_PLANTS/$n_plants/" \
    | sed "s/N_DIFFERENTIAL/$n_differential/" | sed "s/N_DIFFERENTIAL_SAMPLES/$n_differential_samples/" \
    | sed "s/N_DIFF_SPECIES/$n_differential_species/g" | sed "s/N_SPECIES/$n_species/"  > $releaseNotesFile

echo -e "\n\n\n#### Selected new experiments" >> $releaseNotesFile

echo -e "\n#### Selected differential experiments\n" >> $releaseNotesFile
## parse list of new differential studies to get write experiment titles
curl 'https://wwwdev.ebi.ac.uk/gxa/json/experiments' | \
    jq -r '.experiments | .[] | select(.loadDate | strptime("%d-%m-%Y") | mktime > '$last_release_epoch_time') | select(.rawExperimentType | test("DIFFERENTIAL"; "i")) | [.experimentAccession, .experimentDescription] | @tsv' | \
    awk -F'\t' '{ printf "- [%s](https://www.ebi.ac.uk/gxa/experiments/%s)\n", $2, $1}' | sed s/\"//g >> $releaseNotesFile
    awk -v FPAT="^([^,]+)|(\"[^\"]+\")$" '{ printf "- [%s](https://www.ebi.ac.uk/gxa/experiments/%s)\n", $2, $1}' | sed s/\"//g >> $releaseNotesFile

echo -e "\n#### Selected baseline experiments\n" >> $releaseNotesFile
## parse list of new differential studies to get write experiment titles
curl 'https://wwwdev.ebi.ac.uk/gxa/json/experiments' | \
    jq -r '.experiments | .[] | select(.loadDate | strptime("%d-%m-%Y") | mktime > '$last_release_epoch_time') | select(.rawExperimentType | test("BASELINE"; "i")) | [.experimentAccession, .experimentDescription] | @csv' | \
    awk -v FS="," '{ printf "- [%s](https://www.ebi.ac.uk/gxa/experiments/%s)\n", $2, $1}' | sed s/\"//g >> $releaseNotesFile


