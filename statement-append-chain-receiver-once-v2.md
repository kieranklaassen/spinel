<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An append chain written as a statement runs a receiver that is a call once for each link:

```ruby
class Q; attr_reader :s; def initialize(s) = @s = s; end
a = [Q.new(+"p"), Q.new(+"q"), Q.new(+"r")]
b = a.dup
a.shift.s << "x" << "y"
puts b.map(&:s).join(","), a.size   # pxy,q,r and 2 in CRuby; px,qy,r and 1 on master
```

`str_mutate_append_bang_arms` writes the chain as one append a link, and each link was handed the receiver's own text, so the Array was shifted twice. One link had the receiver written again too where its argument is an Integer, a boxed value or an interpolation: `k.b << "a#{v}b#{v}"` ran `b` four times.

The receiver now runs once, ahead of the chain. What was chosen: what is held there is decided by a list (`append_chain_hold`), and whatever the list does not name is the C master writes.

- A reader (`a.shift.s`): its owner is held and the slot is read through it at each link, as master reads it, because a link may put the receiver's String back in the slot under a new handle (`o.s << "a#{o.touch}"`). The owner is held where running it does something or where an argument runs something. `self`, a value object and a `&.` reader, which holds its receiver itself, are not held.
- Any other call (`k.b`): its handle is held, only where no argument runs anything: a String or an Integer literal, a String or an Integer local, `+`, `-` or `*` of such Integers, and `to_s` or an interpolation of these where the program gives Integer no `to_s` of its own.

A local, an instance variable and one plain link keep the C they had. A block's result as the owner (`arr.find { |q| q.s == "p" }.s << "a" << say("b")`) did not build and is right now.

Left as on master: a method's result under an argument that calls (`k.b << f(1) << "z"` runs `b` once a link), a chain past 64 links, and with clang a link whose argument is a call that puts the receiver's String back in its slot. `o.s << "a" << o.touch << "b"` prints `"pab"` for `"pawb"` there and is right with gcc: the C reads the slot and runs the argument in one expression.

Tests: `test/string_append_chain_call_receiver.rb`, 34 lines; master prints 19 of them, 13 wrong, and raises. `test/string_append_chain_integer_to_s.rb` is right on master: the list must not hold there.

Generated C against master (`make cident REF=8684d54c`): `6342 identical, 2 differ, 0 refusal changes` (the two new tests). `tools/refusals.sh` passes (530 records). optcarrot's generated C is byte-identical. Programs, on master 06064727 with CRuby 3.3.6 as the reference: 790 around the chain (the receiver a reader, a method's result, an element, a Struct member, a global, a constant, a local; the arguments literals, locals, interpolations and calls). 215 that are wrong on master are right and 1 that did not build is right; the 474 that are right print the same; 89 that are wrong print the same and 9 do not build, as on master. Two that are wrong on master are wrong another way: a chain that is a lambda's value runs its receiver four times where master runs it six and CRuby two, and `k = a[0].s; a[0].s << "x" << (a.clear; "y")` prints `k` without the appends where master raises with gcc and prints that line with clang (`k` took a copy before the chain; with the receiver in a local master prints the same). Beside them, the block's result above with `o.touch` as a link did not build; it is right with gcc and with clang loses `touch`'s text, as master does with the block's result in a local first.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the tests print Strings, Integers and Arrays of Strings)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
