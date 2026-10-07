<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A proc that returns an empty literal argument answered zeros, or raised, when it was called through a method's parameter. The parameter such a literal reaches is now typed before the fixpoint ends, where nothing else reaches it. Cost, stated first: a value that master types by leaving the untyped parameter out of it is boxed as the parameter is (three shapes below, the answers the same), and compile time grows where the rule fires.

```ruby
def keep(x) = x
def vals(n, k:) = -> { {"n" => n, "k" => k} }
p keep(vals(1, k: [])).call.values
```

```
spinel diff: output-diff
  program: vals.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-[1, []]
+[0, 0]
```

```ruby
def keep(x) = x
def hold(n, k:) = -> { [n, k] }
f = keep(hold(1, k: []))
p f.call
```

```
spinel diff: exception-diff
  program: hold.rb
  ruby:    exit 0
  spinel:  exit 1
  exception (ruby):   (none)
  exception (spinel): TypeError: an Array holding Array reached a slot typed as an Integer Array

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +0,0 @@
-[1, []]
```

The same with `k: {}` and with a positional `{}` (`def hold(n, k)`, `hold(1, {})`), and without a method that hands the proc back: `def run(x) = x.call` raises as well. A positional `[]` is right.

A parameter that only an empty literal reaches has no type of its own. The backstop bind pass, run once as the fixpoint converges, types it for a positional `[]`, and the fixpoint goes on so that what was read from the parameter is read again. An empty keyword literal and a positional `{}` had no such rule: `k` stayed untyped to the end and was boxed afterwards (never bound). By then the proc's return, read as an Integer Array while `k` had no type, was the type `keep`'s `x` calls the proc by; a slot that takes a proc only unifies, and nothing after the fixpoint reads again what was typed from `x.call`.

The pass notes the empty `{}` and the keyword's empty literal (`bind_note_untyped`), and boxes the parameter once it has read every call site (`bind_empty_literal_params`), where no other argument reaches it untyped. One that does, such as a local `e = []`, is typed after the fixpoint and types the parameter the container, as it did: those programs compile to master's C. A keyword's `[]` is boxed, not the untyped array a positional one is: beside a `{}` from another call site the keywords have no rule to widen under, and the two would not build.

Cost:

- A value typed by leaving the untyped parameter out of it, and right because the parameter was empty, is boxed. Three shapes, the answers the same on both:

| shape | instructions, master | here |
|---|---|---|
| `-> { k.empty? ? [n] : k }`, a million calls of the proc | 418,334,940 | 482,338,322 |
| `-> { k[0] = n; k }` with `k: {}`, a million calls | 294,669,249 | 339,669,299 |
| `@k = k`, a million `@k << x` and one `@k.each` | 211,941,586 | 215,941,596 |

- Compile time: the fixpoint runs on where the rule fills a parameter, as it does for a positional `[]`. It fires in 8 programs of `test/`, whose C is unchanged: 1,385,937,253 instructions to compile them on master, 1,541,379,446 here. optcarrot: the same C and the same count (8,122,516,864 and 8,122,260,755). optcarrot with the second program above added: 8,210,339,772 on master, 9,827,045,254 here; with its positional twin (`hold(1, [])`) master takes 9,750,200,189.

Not here, the same on master: `k: Array.new` (no literal) raises or answers zeros the same way; `k: []` beside `k: "s"` at another call site does not build; `-> { k[0] = n; k }` with `k: []` does not build.

Test: `test/empty_literal_keyword_proc_return.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: nothing
