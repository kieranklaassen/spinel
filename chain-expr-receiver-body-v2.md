<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
a = +""; b = +""; c = ARGV.size > 5
(c ? a : b) << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8"
p b
```

```
spinel diff: output-diff
  program: chain.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-"12345678"
+"1234567"
```

The compile warns that type inference did not converge in 128 rounds. At 34 links the compiler crashes. Seven links, which master gets right, take `spinel -c` 607,289,630 instructions, and 39,369,520 here (callgrind).

`desugar_mutator_receiver_value` moves a mutator call into the arms of its conditional receiver, one call a round, and leaves a paren where the call stood. The next link has to cross every paren the links before it left, so each link takes about twice the rounds of the one before. The eighth is still outside when the rounds run out and appends to a copy; at 34 links the parens nest deeper than the analyzer's walk has stack for.

The links of a chain now go into the arms together, in three rounds at any length, where every change is then kept: the chain is a statement, all its links are `<<` (at most 65 calls, the number the append chain's emitter writes) or links the chain's write-back passes (`insert` at 0 or -1, `prepend`, `concat`, `replace`, `<<`, with a bang allowed last; pull request 7778), and every path of the receiver ends in a String local no closure writes. Any other chain moves a call a round, as before.

A chain on a plain local is not this pass's: 200 `concat` calls on one compile in 11,131,337,835 instructions on master and 11,131,339,952 here. At run time no chain costs more: 200,000 runs of the seven links take 544,813,035 instructions on master and 544,442,181 here, of two links 291,485,292 and 291,480,124.

| `<<` calls on `(c ? a : b)` | master | here |
|---|---|---|
| 8, 33 | 7 appended, with the warning | right |
| 34, 65 | the compiler crashes | right |
| 66 and more | the compiler crashes | the compiler crashes |

Not here: a chain of `<<` alone past 65 calls (moved together it would build and append 65 in silence); a chain whose value is read (`t = (c ? a : b) << "1" << "2"`), which moves a call a round as before: right up to seven links, and from the eighth `b` still misses the rest.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
