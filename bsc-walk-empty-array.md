<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`make san-check` is red on master. The smallest program that shows it:

```ruby
class String; def none; []; end; end
```

```
runtime error: null pointer passed as argument 2, which is declared to never be null
```

at the `memcpy` in `bsc_walk`, under `desugar_builtin_reopen_self_class` (`src/analyze_desugar.c`). `bsc_walk` (57b11157, "self.class in a reopened builtin is that builtin") copies each array of a node before walking it, and an empty array's `ids` is NULL: `memcpy` from NULL is undefined even for length 0. An instance method of a reopened String, Array, Hash, Integer or other one-class builtin reaches it when its body holds a node with an empty array, as `[]` does.

fbb5714f gave `cbs_walk`, the walk above it in the same file, `if (an <= 0) continue;` for the same report. This is that line in `bsc_walk`, with its comment. Nothing else changes.

No new test: `make san-check` is the test, and `test/builtins_integer_digits_reopen.rb` is one of the programs that report.

| | master 3c4334f8 | this branch |
|---|---|---|
| `make san-check` | 5948 programs, 80 with a report (this one site) | 5948 programs, 0 with a report |

The 5,948 are the corpus's 5,947 programs and optcarrot. The generated C does not change. `tools/cident.sh` against 3c4334f8: `5948 identical, 0 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (no new test)
- [ ] Values past 2^31 are marked `# spinel: int64` (no new test)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
