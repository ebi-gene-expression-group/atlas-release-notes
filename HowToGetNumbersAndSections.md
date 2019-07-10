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
curl 'https://wwwdev.ebi.ac.uk/gxa/sc/json/experiments' | jq -r '.aaData | .[] | select(.lastUpdate | strptime("%d-%m-%Y") | mktime > 1552867200) | [.experimentAccession, .experimentDescription] | @csv' | awk -v FS="," '{ printf "- [%s](https://www.ebi.ac.uk/gxa/sc/experiments/%s)\n", $2, $1}' | sed s/\"//g
```

On a mac you could pipe the above command to `pbcopy` and that will leave everything in your clipboard.
