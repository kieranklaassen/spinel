<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A Range the compiler types as a Range, splatted into one of the program's own methods, went over as one value:

```ruby
def f(*r) = r
p f(*(3..4))            # [3..4]; CRuby [3, 4]
def g(a, b) = [a, b]
v = 3..4
p g(*v)                 # [[3..4], 0]; CRuby [3, 4]
def m(*a) = a.sum
p m(*1..3)              # TypeError; CRuby 6
```

An Enumerator went over as the one value too. `desugar_splat_to_a` already rewrites a splat's operand to its `to_a` for a Hash, a Struct and an object that defines `to_a`, so that the array splat paths see an Array. It now does so for an operand typed as an Integer Range, a String Range or an Enumerator, when the splat is an argument of a call whose name the program defines, a required package's methods among them, or of `super` (`splat_feeds_user_method`). The parameters are bound from the Array, and a call that gives too many raises ArgumentError as in CRuby. The rewrite waits for the settled rounds of inference, where the operand's kind is no longer a guess.

Not changed here:

- The builtins and the array literal spread a typed Range in their own arms and are left alone. A method of the program that shares its name with such a builtin is not reached when the Range is held in a variable: with `def start_with?(*a) = a.size`, `r = "a".."b"; u.start_with?(*r)` still answers 1, where `u.start_with?(*("a".."b"))` now answers 2.
- A constructor is left as it was, whatever else the program names `new`. `K.new(*a)` into a rest `initialize`, and `S.new(*a)` on a Struct, do not root the splatted array on master (`SPINEL_GC_STRESS=2` shows it), and a Range sent down that path would join them. Only a class method `new` of the receiver's own class, called on the class by its plain name, is given the members; called through a path (`M::W.new(*r)`) or with no receiver inside the class, it still takes the Range as the one value.
- `method(:f).call(*r)` is not reached.

One test, `test/splat_range_into_method_arguments.rb`. On master c1d108abe with the pull requests this one depends on, its first three lines are wrong and the fourth raises TypeError; with this commit all 42 are right, under `SPINEL_GC_STRESS=1` and `=2` too. Of the 6,035 programs in `test/`, `benchmark/` and `packages/*/test/`, the generated C of 6,034 is the same as without this commit; the one that differs is the new test.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (CRuby 4.0.7 with that flag prints exactly the test's `.expected`)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical, compared at 08bf767fb where this commit was written)
- [ ] Depends on: #FIRST_SPLAT_PR, #SECOND_SPLAT_PR ("A splat pushed onto an empty array literal spreads its elements" and "A splat spreads a boxed Range's members and an Enumerator's items"; this commit sits on those two)
