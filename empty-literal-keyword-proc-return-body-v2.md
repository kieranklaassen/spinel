<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A proc that returns an empty literal argument answered zeros, or raised, when it was called through a method's parameter. The parameter such a literal reaches is now typed before the fixpoint ends, where nothing else reaches it and the method only holds it in the literal a proc returns. Cost, stated first: compile time grows where the rule fires (nowhere in `test/` or optcarrot today; figures below), and a proc's Hash whose values the program never reads holds boxed values, 75 instructions a call.

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

The same with `k: {}` and with a positional `{}` (`def hold(n, k)`, `hold(1, {})`), with the parameter filled first (`k << n` before the proc or in it), and without a method that hands the proc back: `def run(x) = x.call` raises as well. A positional `[]` is right.

A parameter that only an empty literal reaches has no type of its own. The backstop bind pass, run once as the fixpoint converges, types it for a positional `[]`, and the fixpoint goes on so that what was read from the parameter is read again. An empty keyword literal and a positional `{}` had no such rule: `k` stayed untyped to the end and was boxed afterwards (never bound). By then the proc's return, read as an Integer Array while `k` had no type, was the type `keep`'s `x` calls the proc by; a slot that takes a proc only unifies, and nothing after the fixpoint reads again what was typed from `x.call`.

The pass notes the empty `{}` and the keyword's empty literal (`bind_note_untyped`), and boxes the parameter once it has read every call site (`bind_empty_literal_params`), where no other argument reaches it untyped. One that does, such as a local `e = []`, is typed after the fixpoint and types the parameter the container, as it did. A keyword's `[]` is boxed, not the untyped array a positional one is: beside a `{}` from another call site the keywords have no rule to widen under, and the two would not build.

Only where that return is all the method does with the parameter (`param_held_by_proc_literal`): each read of it is an element of the Array or Hash literal a proc made in the method answers with, or the receiver of a fill whose value is dropped (`k << e`, `k.push(e)`, `k[i] = e`). A bare `super` hands every parameter on, and is a read of another kind. Any other read was typed without the parameter, and the method compiles to master's C: boxed before the fixpoint ends, `k` changes the route of every call on it, and a method that is right on master (`-> { k.empty? ? [n] : [n, k] }`, `-> { k.max_by { |x| x.to_s }; [n, k] }`) would pay for the box. Both are lines of the test, and so is the bare `super`.

Depends on the pull request "A method inlined in a proc keeps its own variable where the proc captures one of that name". The parameter boxed in time, a call on what the proc answers reaches a builtin it never reached while the parameter had no type, and `max_by` took a captured `n` for its own:

```ruby
def keep(x) = x
def hold(n, k:) = -> { [n, k] }
f = keep(hold(1, k: []))
n = 3
g = -> { n += 1; f.call.last.max_by { |x| x.to_s } }
p g.call, n
```

On master this raises the TypeError above; with this change alone the C does not build (`builtins/enumerable.rb:148`); above that pull request it prints `nil` and `4`. It is the last case of the test, so the test does not build without it. A proc that fills the parameter and calls `max_by` on it without answering a literal that holds it (`-> { k << n; k.max_by { |x| x.to_s } }`) is master's C, called or not.

Measured with gcc and clang at `SPINEL_GC_STRESS` 0 to 2 over 28,453 programs (each empty literal, 32 proc bodies, 26 fills, the proc called where it is made and through a parameter, each with a twin whose use never runs), on master 8dc5522541bb: 4,639 change their C. Of the 2,357 that run, 2,219 wrong or refused on master are right and 138 are right on both; the 2,282 twins all build. None right on master is wrong, refused or unbuildable.

Cost:

- Compile time: the fixpoint runs on where the rule fills a parameter, as it does for a positional `[]`. It fires in no program of `test/` but this test, and not in optcarrot (the same C; 8,340,719,297 instructions to compile it on the parent, 8,340,976,492 here). optcarrot with the second program above added: 8,426,699,395 on the parent, 10,065,396,120 here; with its positional twin (`hold(1, [])`) the parent takes 9,989,896,998.
- Run time, the 138 right on both: 56 raise as CRuby does (`{} << n`); 68 never read what the literal holds (`f.call.size` of the Hash: 976 instructions a call on master, 1,051 here, the values boxed where master's Hash held zeros); 14 read it through `inject` (2,291 a call on both).

Not here, the same on master:

- the parameter read another way beside the literal (`[n, k.dup]`, `r = [n, k]; r`, `n > 0 ? [n, k] : [k, n]`, `@k = k`, `k << n if n > 0`) still raises or answers zeros;
- the empty literal handed on through a second method (`def outer(k:) = hold(4, k: k)`, `outer(k: [])`) still raises: `outer` reads its parameter as an argument;
- `k: Array.new` (no literal) raises or answers zeros the same way; `k: []` beside `k: "s"` at another call site does not build;
- `keep(vals(1, k: [])).call.merge({})` aborts under `SPINEL_GC_STRESS=2` with gcc: a boxed Hash merged with a fresh one is not held, as on master where a method answers a Hash or an Array (`pick(true).merge({})`).

Test: `test/empty_literal_keyword_proc_return.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: "A method inlined in a proc keeps its own variable where the proc captures one of that name"
