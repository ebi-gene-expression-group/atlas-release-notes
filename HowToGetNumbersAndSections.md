# GXA - Bulk release notes

## Short cut
The following script will generate a template release notes file at release-notes/gxa/_posts/YEAR-MONTH-DAY-RELEASE.md:


```
bash gxa_helper/bin/gxa_release_data_stats.sh <release_number> <list_of_new_differential_studies> <list_of_new_baseline_studies>
```
This script will populate data statistic and release notes by extracting data stats and experiment titles using curl and jq queries. 

Firt arg - release_number
Second args - list of new differential study accession in a newline txt format
Third args - list of new baseline study accession in a newline txt format

You need to edit release-notes/gxa/_posts/YEAR-MONTH-DAY-RELEASE.md with Ensembl and E! genome WBPS version numbers once popluated


# Single cell

## Short cut

The following script will generate a template release notes file at release-notes/sc/_posts/YEAR-MONTH-DAY-RELEASE.md:

```
bash sc_helper/bin/start_new_release_notes.sh
```

This will guess YEAR-MONTH-DAY based on the current date, and increment from the last release derived from previous release notes. But you can supply these respective parameters as arguments.

You must set ATLAS_SC_EXPERIMENTS correctly and have access to `jq`.

Edit the resulting file to get the final release notes file and generate a pull request for it.

## Number of cells

These values reside currently in `$ATLAS_SC_EXPERIMENTS/cell_stats.json`.

## New experiments since last release

The release notes are named according to date. Clone this repository and run the following commands from the top level.

Fetch the epoch age for the newest release like:

```
last_release_epoch_time=$(ls -t release-notes/sc/_posts/ | sed 's/.md//' | awk -F'-' '{print $2"/"$3"/"$1}' | while read -r l; do date "+%s" -d "$l"; done | sort -nr | head -n 1)
```
Then we can filter to fetch just the experiments added since that time:
```
curl 'https://wwwdev.ebi.ac.uk/gxa/sc/json/experiments' | 
	jq -r '.experiments | .[] | select(.lastUpdate | strptime("%d-%m-%Y") | mktime > '$last_release_epoch_time') | [.experimentAccession, .experimentDescription] | @csv' | \
	awk -v FS="," '{ printf "- [%s](https://www.ebi.ac.uk/gxa/sc/experiments/%s)\n", $2, $1}' | sed s/\"//g
```

## Top 15 species by studies count overall in atlas (including single cell expression atlas)

```
IFS="
"

all_species=`curl -s https://wwwdev.ebi.ac.uk/gxa/json/experiments | jq '.experiments | .[].species' | sort -u`

for species in $all_species; do
	 differential_studies=`curl -s https://wwwdev.ebi.ac.uk/gxa/json/experiments | jq '.experiments | map(select(.species | contains('"$species"'))) | map(select(.rawExperimentType | test("(MICROARRAY)|(DIFFERENTIAL)"; "i"))) | length'`
	 baseline_studies=`curl -s https://wwwdev.ebi.ac.uk/gxa/json/experiments | jq '.experiments | map(select(.species | contains('"$species"'))) | map(select(.rawExperimentType | test("(BASELINE)"; "i"))) | length'`
	 singlecell_studies=`curl -s https://wwwdev.ebi.ac.uk/gxa/sc/json/experiments | jq '.experiments | map(select(.species | contains('"$species"'))) | map(select(.rawExperimentType | test("(BASELINE)"; "i"))) | length'`
	 echo -e $species"\t"$differential_studies"\t"$baseline_studies"\t"$singlecell_studies	>> species_stats.txt
done

### top 15
echo -e "Species\tNumber_of_differential_studies\tNumber_of_baseline_studies\tNumber_of_singlecell_studies" > top_15_species.txt	
sort -r -nk3 species_stats.txt  | head -n15 >> top_15_species.txt

## include `Others` species as cumulative count as last row
differential_others=`sort -r -nk3 species_stats.txt | awk 'NR>15' | cut -f2 | awk '{total += $0} END{print ""total}'`
baseline_others=`sort -r -nk3 species_stats.txt | awk 'NR>15' | cut -f3 | awk '{total += $0} END{print ""total}'`
sc_others=`sort -r -nk3 species_stats.txt | awk 'NR>15' | cut -f4 | awk '{total += $0} END{print ""total}'`
echo -e "Others\t$differential_others\t$baseline_others\t$sc_others" >> top_15_species.txt
```
On a mac you could pipe the above command to `pbcopy` and that will leave everything in your clipboard.
