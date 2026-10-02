<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A method forwarding `...` to another forwarder did not build when it was written above the one it calls:

```ruby
def top(...) = mid(...)
def mid(...) = leaf(...)
def leaf(a) = a * 2
puts top(21)        # error: passing argument 1 of 'sp_mid' makes pointer from integer without a cast
```

With `mid` written first it built and printed 42.

`desugar_forwarding_to_rest_callee` rewrites `def m(...) = f(...)` into `def m(*, **, &) = f(*, **, &)` from the shape of `f`, and walked the defs once, in source order. A `...` forwarder has no shape of its own until it is rewritten, so one standing above its callee read none, kept the `__fwd_N` model with one parameter per argument, and passed its Integer to a callee that had since become `def mid(*)`. A forwarder now waits until no def of its target's name still takes `...`, so the callee is rewritten first wherever it stands, and the walk (`fwd_rest_callee_pass`) repeats until nothing changes. What is left then waits on a forwarder that keeps the `__fwd_N` model (a cycle, a target that yields) and is read as before, from the defs that do say.

With two defs of the target's name it was a wrong answer and not a failed build:

```ruby
def either(o, ...) = o.em(...)
class Plain
  def em(*r) = [:Plain, r]
end
class Fwd
  def em(...) = et(...)
  def et(*r, **k) = [:Fwd, r, k.to_a]
end
p either(Fwd.new, 1, z: 2)    # [:Fwd, [1, {z: 2}], []]   CRuby: [:Fwd, [1], [[:z, 2]]]
```

`either` took the shape of `Plain#em` alone, so the keyword reached `Fwd#em` as one more positional. The same wait builds `super(...)` into a parent method that a later reopening of the parent defines, and `new(...)` from a method above the class whose initialize forwards; neither built before.

Found with `tools/order_probe.rb` (#7099): reversing the defs of `test/forward_args.rb`, `forward_args_block.rb`, `forward_all_no_keywords.rb` and `arg_forwarding_to_no_params.rb` gave C that did not build. Over `test/*.rb` the probe reports 19 programs on 0d370b71 and 15 with this change, with none of class `shape` left. No program in `test/`, `test/reject/`, `test/infer/`, `benchmark/`, `examples/` or the packages' tests has a forwarder above the one it calls: the emitted C of all 5,903 is byte-identical before and after (both compilers built on 0d370b71), so nothing that built before changes.

`test/forward_args_callee_below.rb` has chains of two and four, a block, keywords into a `**nil` target and an argument into one taking none (both raise CRuby's ArgumentError through the chain), `new(...)`, `super(...)` into a reopened parent, and the two-def case above. It prints its `.expected` plain and under `SPINEL_GC_STRESS=1`, and does not build on master. The change is 43 lines in `src/analyze_desugar.c`: the walk is the old function under a new name (195 lines) with one line added, beside two helpers and the loop.

Not changed: two forwarders that call each other, and a forwarder into one that keeps the `__fwd_N` model, are read in source order as before.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag; it prints Integers, Symbols, Arrays of them and two ArgumentError messages, and no Hash)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (OPTCARROT_LINE)
- [ ] Depends on: # (nothing; #7099 is the probe that found it and is merged)
