# Atlas Release notes

This is a static site containing all the release notes for [Expression Atlas](https://www.ebi.ac.uk/gxa) and [Single
Cell Expression Atlas](https://www.ebi.ac.uk/gxa/sc). The GitHub Pages are automatically deployed and updated on each
push. You can see them following [this link](https://ebi-gene-expression-group.github.io/atlas-release-notes/).

## How to run it

You will need a Ruby environment with RubyGems and Bundler. The most convenient way is to install
[RVM](https://rvm.io/).

Clone the repository and within its directory run:
```
bundle install
```

To see the site locally:
```
bundle exec jekyll serve
````

And follow the instructions on the terminal.

## Post new release notes
Curators need to create a branch with the name `release/<story-id-from-Pivotal-Tracker>-<project>-<version>` (e.g.
`release/162089283-gxa-29` and upload a Markdown file with the name formatted as `YYYY-MM-DD-<release number>` in the
directory `release-notes/gxa/_posts` for bulk Expression Atlas releases, or in `release-notes/sc/_posts` for Single
Cell Expression Atlas releases. If an image is included, please refer to the post
[`2015-03-20-note.md`](https://github.com/ebi-gene-expression-group/atlas-release-notes/blob/master/_posts/2015-03-20-note.md)
and upload the image to the `assets/img/` directory. After pushing the branch wait for the release to happen and then
merge into `master`.
