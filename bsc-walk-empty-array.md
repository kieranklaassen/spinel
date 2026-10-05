<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

On Linux, `make san-check` is red on master. The smallest program that shows it:

```ruby
class String; def none; []; end; end
```

```
runtime error: null pointer passed as argument 2, which is declared to never be null
```

at the `memcpy` in `bsc_walk`, under `desugar_builtin_reopen_self_class` (`src/analyze_desugar.c`). `bsc_walk` (57b11157, "self.class in a reopened builtin is that builtin") copies each array of a node before walking it, and an empty array's `ids` is NULL, so the call is a `memcpy` from NULL with a length of 0. An instance method of a reopened String, Array, Hash, Integer or other one-class builtin reaches it when its body holds a node with an empty array, as `[]` does.

fbb5714f gave `cbs_walk`, the walk above it in the same file, `if (an <= 0) continue;` for the same report. This is that line in `bsc_walk`, with its comment. Nothing else changes.

Where it shows: glibc declares `memcpy` with `__nonnull ((1, 2))`, and UBSan's nonnull-attribute check reports the call. The macOS SDK declares `memcpy` without that attribute, so on macOS the check prints no report with or without this line.

| `make san-check` | master | this branch |
|---|---|---|
| Linux x86_64, gcc 13.3.0, glibc 2.39 (master 3c4334f8) | 5948 programs, 80 with a report (this one site) | 5948 programs, 0 with a report |
| macOS 27.0 arm64, Apple clang 21.0.0 (master 4db93537) | 5951 programs, 0 with a report | 5951 programs, 0 with a report |

No new test: `make san-check` on Linux is the test, and `test/builtins_integer_digits_reopen.rb` is one of the 80.

The generated C does not change. `tools/cident.sh` against 3c4334f8: `5948 identical, 0 differ, 0 refusal changes, 0 refused by both, 0 not in the reference` (the corpus's 5,947 programs and optcarrot).

## `make gate` (on this branch merged with current master)

On macOS 27.0 arm64 (Apple clang 21.0.0, GNU Make 3.81, ruby 4.0.7), this branch merged into master 4db935375:

```
scale-test: instance_eval forwarding work at 2x the wrappers is 1.74x (limit 2.50)
scale-test: work at 4x the program is 4.74x (linear 4.00, limit 5.20)
scale-test: work at 4x the program, compiled to C, is 6.10x (limit 6.90)
scale-test: call-shape work at 4x the units, compiled to C, is 4.22x (linear 4.00, limit 4.50)
Tests:     5864 pass,        0 fail,        0 error
gate: ALL GREEN
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (no new test)
- [ ] Values past 2^31 are marked `# spinel: int64` (no new test)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change; checksum 59662)
- [ ] Depends on: # (nothing)
