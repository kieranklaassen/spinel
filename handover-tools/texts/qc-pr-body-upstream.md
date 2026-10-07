<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Compile time, for a class that includes a diamond of modules (two modules a level, each including both of the level below) and reads a constant that several bodies define:

| levels | master | this branch |
|---|---|---|
| 14 | 0.01 s | 0.01 s |
| 18 | 0.15 s | 0.01 s |
| 22 | 2.5 s | 0.01 s |
| 24 | 10.1 s | 0.01 s |
| 26 | 43.5 s | 0.01 s |
| 30 | 862 s | 0.01 s |

User time of `spinel -S`. CRuby runs the 30-level program in 0.08 s.

```ruby
module Lib;  class X; end; end
module Lib2; class X; end; end
class X; def hi = "hi"; end
module A3; end; module B3; end
module A2; include A3, B3; end; module B2; include A3, B3; end
module A1; include A2, B2; end; module B1; include A2, B2; end
class User; include A1; def go = X.new.hi; end
```

A name several bodies define is looked up through the ancestors of the body that reads it (`qc_ancestor_lookup`), and the walk took every path through the includes: 2**levels walks where nothing on the way defines the name.

A module the walk leaves without a match is now marked with the walk's number and the depth it stood at, and is not walked again from as deep or deeper. The bound of 32 cuts the second walk no later than the first, so it finds nothing the first did not. The body the read sits in is asked without its own write and keeps no mark.

No answer changes: `tools/cident.sh` against master reads 6393 identical, 0 differ, and 435 generated graphs of include, prepend and superclass (diamonds, chains past the bound, include cycles, reads that reach no write) emit master's C or master's refusal.

Test: `test/const_read_include_diamond.rb`, 30 levels.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
