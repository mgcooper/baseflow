# Vendored m2html

This folder holds a copy of M2HTML. `baseflow.internal.makedocs` uses it
to build the function reference pages in `toolbox/docs/html/m2html`.

## Source

- Upstream: https://github.com/rochefort-lab/m2html
- Commit: `3821fb86478e79a092d46b93b7bf63bf48bd7e4c` (2016-02-03)
- Origin: M2HTML v1.5 by Guillaume Flandin. The rochefort-lab repository
  is a fork of that release.

## License

M2HTML is licensed under GPL-2.0-or-later. See `LICENSE` and `GPL`.
M2HTML is a separate program that the repository stores next to the
toolbox. It is not part of the baseflow toolbox, and the toolbox license
does not change.

## Local changes

- `m2html.m`: `dot_exec` looks for Graphviz `dot` in `/usr/local/bin`,
  then in `/opt/homebrew/bin`. Homebrew on Apple silicon installs `dot`
  in `/opt/homebrew/bin`. The header of `m2html.m` records this change.
- `templates/blue2_baseflow/`: a copy of the upstream `templates/blue2/`.
  Only `master.tpl` differs: its title and headings name the baseflow
  toolbox.

## Files left out

The build does not use these upstream files, so this folder does not
include them:

- `mwizard.m` and `mwizard2.m`
- `private/m2htmltoolbarimages.mat`
- the templates other than `blue2_baseflow`, and `templates/3frames.zip`
- `Changelog`, `INSTALL`, `TODO`, and `Contents.m`
- `.gitattributes` and `.gitignore`

## Keep the upstream layout

m2html finds its templates in the `templates` folder next to `m2html.m`.
The `@template` class and the `private` folders must also stay next to
`m2html.m`. Do not move files inside this folder.

## Refresh from upstream

1. Clone https://github.com/rochefort-lab/m2html and check out the
   target commit.
2. Copy the files that this folder holds from the clone. Use `cp`, and
   keep the folder layout.
3. Apply the `dot_exec` change to `m2html.m` again. Keep the dated line
   in the header.
4. Copy `templates/blue2/` to `templates/blue2_baseflow/`. Apply the
   `master.tpl` title and headings from the previous copy.
5. Run `git ls-files tools/m2html/templates/blue2_baseflow/todo.tpl`
   from the repository root and confirm that Git tracks the file. A
   machine-local `todo*` rule in `.git/info/exclude` hides a new copy of
   the file, so add a new copy with `git add -f`.
6. Record the new commit in this file.
7. Run `baseflow.internal.makedocs('functions')` and review the changes
   in `toolbox/docs/html/m2html`.
