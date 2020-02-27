# Single cell

## Number of cells

These values reside currently in `$ATLAS_SC_EXPERIMENTS/cell_stats.json`.

## New experiments since last release

First get the seconds since epoch for the last release date (write it as dd-mm-yyyy, replacing the date below):

```
# be mindful of the quoting structure!
echo '"18-03-2019"' | jq 'strptime("%d-%m-%Y")|mktime'
```

Then execute this (replacing the value for what goes after mktime) and copy the output to the release notes:

```
curl 'https://wwwdev.ebi.ac.uk/gxa/sc/json/experiments' | jq -r '.experiments | .[] | select(.lastUpdate | strptime("%d-%m-%Y") | mktime > 1552867200) | [.experimentAccession, .experimentDescription] | @csv' | awk -v FS="," '{ printf "- [%s](https://www.ebi.ac.uk/gxa/sc/experiments/%s)\n", $2, $1}' | sed s/\"//g
```

Top 15 species by studies count overall in atlas (including single cell expression atlas)

```
IFS="
"

all_species=`curl -s https://wwwdev.ebi.ac.uk/gxa/json/experiments | jq '.experiments | .[].species' | sort -u`

for species in $all_species; do
	 differential_studies=`curl -s https://wwwdev.ebi.ac.uk/gxa/json/experiments | jq '.experiments | map(select(.species | contains('"$species"'))) | map(select(.experimentType | test("(MICROARRAY)|(DIFFERENTIAL)"; "i"))) | length'`
	 baseline_studies=`curl -s https://wwwdev.ebi.ac.uk/gxa/json/experiments | jq '.experiments | map(select(.species | contains('"$species"'))) | map(select(.experimentType | test("(BASELINE)"; "i"))) | length'`
	 singlecell_studies=`curl -s https://wwwdev.ebi.ac.uk/gxa/sc/json/experiments | jq '.experiments | map(select(.species | contains('"$species"'))) | map(select(.experimentType | test("(BASELINE)"; "i"))) | length'`
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
