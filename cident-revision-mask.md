<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

One line in `tools/cident.sh`. In a clone that cannot see the release tag, `make cident` reports four programs for a commit that changes no C:

```
$ git clone --shallow-since=2026-10-03 https://github.com/matz/spinel
$ make deps && make          # then commit a change to a tool
$ make cident
DIFFERS: test/frozen_chilled_builtin_strings.rb
DIFFERS: test/object_scoped_ruby_constants.rb
DIFFERS: test/ruby_description_shape.rb
DIFFERS: test/symbol_id2name_ruby_desc_minmax.rb
cident: 6042 identical, 4 differ, 0 refusal changes, 0 refused by both, 0 not in the reference (against ebb73f701)
```

The Makefile writes the release into `RUBY_DESCRIPTION` as `2026.09.12` when HEAD is the release, `2026.09.12+N` past it, a four-part tag in either form, and `unreleased` when `git describe` finds no release tag. The filter of 330a29fe knows the three-part `+N` form alone, so the four programs that print `RUBY_DESCRIPTION` still differ:

- in a clone without the tag (a shallow one, a fork that never fetched it), where both sides say `unreleased revision <sha>`;
- in a full clone, against the release commit itself: `2026.09.12 revision <sha>` on one side, `2026.09.12+1 revision <sha>` on the other;
- with a four-part release tag, on every commit past it.

`NORM` now takes each form the rule can write.

This is not a regression, and it blocks no one: `make cident` is not part of `make gate` and CONTRIBUTING.md does not name it.

Measured on ebb73f70 with this one commit on top, 6,046 programs, master's filter and the changed one on the same compilers, the reference being HEAD~1. A local tag stands in for a release.

| situation | master's filter | changed |
|---|---|---|
| no tag in sight (`unreleased` on both sides) | 4 differ | 0 |
| the reference is a three-part release (`2026.10.05`, `2026.10.05+1`) | 4 differ | 0 |
| the reference is a four-part release (`2026.10.05.1`, `2026.10.05.1+1`) | 4 differ | 0 |
| both builds past a four-part release (`2026.10.05.1+6`, `+7`) | 4 differ | 0 |

With both builds past a three-part release, the form master's filter knows, both report 0 (run on ab9b925a). Against a reference before #7373 both report `test/boxed_each_line_args.rb`, whose C that change did alter, and the lists differ by the four and nothing else (ab9b925a).

What it costs: the filter also rewrites a program's own text of this shape, and after `unreleased revision` any run of digits and the letters a to f, so two compilers that wrote different bytes inside such a literal would be reported as identical; no source in the corpus holds such text. And cident no longer shows which release label a build stamps. CRuby's own `ruby 4.0.7 (2026-09-15 revision ...)` is not touched: it is written with dashes.

The expression is POSIX extended syntax (a group, `|`, `?`, `{n}`), given to `sed -E` as the line it replaces was. It ran with GNU sed 4.9; BSD sed was not run.

No test is added: nothing in the tree runs cident, and a test of it would build the compiler twice.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (none added)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (no compiler source changes)
- [ ] Depends on: #
