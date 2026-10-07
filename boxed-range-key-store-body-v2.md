<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
Pt = Struct.new(:x, :y)
def pick(i) = [+"abcdef", [1, 2, 3, 4], Pt.new(1, 2)][i]
s = pick(0)
s[1..2] = "-"
p s    # CRuby: "a-def"; master: "abcdef"
```

`spinel diff` on master: output-diff, `"abcdef"` for `"a-def"`; on this branch: same.

The store is dropped with no error, and only because the program has a Struct. Without the `Pt` line master prints `"a-def"`. The Array beside it is refused at run time: `a = pick(1); a[1..2] = [9]` raises TypeError, no implicit conversion of Range into Integer, where CRuby prints `[1, 9, 4]`.

`x[k] = v` on a boxed receiver goes to the class dispatch as soon as a class in the program takes `[]=` with two arguments, and every Struct does. The dispatch has an arm for each such class; any other receiver stores through `sp_poly_set_poly` with the key boxed. A boxed Range is no Integer there, so an Array raised. A String has an arm of its own ahead of the switch, for an Integer, String, Regexp or boxed key; a Range key missed it, fell to the same default, and that default does nothing for a String. With no such class in the program the builtin path splices both (`sp_poly_splice_range`).

`sp_poly_set_poly` now splices an Array for a Range key; the test sits in the branch that raised, so an Integer key pays nothing. The dispatch's String arm takes a Range key too (`src/codegen_poly_plan.c`): `sp_poly_str_aset_key` reads its span, a plain String is written back to a local or an instance variable and a shared one changes in place, as for the other keys. A boxed key that holds a Range (`k = [1..2, 0][0]; a[k] = [3]`) reaches the same Array arm with no class in the program; it raised the same TypeError and splices now.

Measured against CRuby, each program with gcc and with clang, plain and under `SPINEL_GC_STRESS=2`:

- 1,296 programs (beside a class of the program's and beside a Struct; an Array of Integers, of Strings and mixed, a String, a frozen String, a frozen Array, a Hash, nil and the class's own object as the receiver; in a local, an instance variable, a parameter and an element written in the Array's literal, `row = [+"abcdef", 0]`; nine Ranges, `1..2`, `1...3`, `2..`, `..1`, `-2..-1`, `9..10`, `-9..1`, `i..j` and a boxed one; a value that fits and one of another kind): 800 made right, 178 right on both, none lost. The other 318 are under "Not here".
- `make cident`: the generated C of the corpus is unchanged; the two new tests are the only programs whose C differs.
- callgrind, a million stores beside a class that owns `[]=`: an Integer index into a boxed Array 119,676,526 to 119,676,757, into a boxed String 1,327,605,421 to 1,327,604,479, into the class's own object 39,668,704 to 39,668,917; a String key into a boxed Hash 209,674,348 to 207,674,534; a boxed key with no class 94,673,443 to 94,673,494. A second measure of twenty-one loops: with gcc one pays one instruction a store (`a[1] = i` on a boxed Array of Integers with no class, 63 to 64: the new branch moves gcc's registers) and three save one; with clang none pays.

Not here, the 318, each the same output on master unless said:

- a Hash receiver (140): a Range key into a Hash typed with String keys stays the loud "cannot store a Range key ... (the hash was not widened for this store)";
- the class's own object (144): a Struct given a Range key raises NameError, no member '..1' in struct (TypeError in CRuby), and `p((x[..1] = :v))` on the class's object prints what its `[]=` returns, not `:v`;
- an Array typed by its elements given a value of another kind (16, an Array of Strings spliced past its end, which CRuby pads with nil; `a[1..2] = "s"` on an Array of Integers is the same): master raised the TypeError above, this branch raises the loud "can't store String in an Array of Integer through a boxed receiver", as master does for that store with no class in the program;
- a frozen String (16): given a Range that starts outside it, `9..10` or `-9..1`, CRuby raises RangeError; master went on in silence, this branch raises FrozenError. Given a value that is no String it is FrozenError for CRuby's TypeError;
- beside a class with its own `[]=`, `p((@x[k] = "-"))` with `k` a boxed Range and `@x` out of `[+"abcdef", 0][0]` (2): right in a plain run, aborts under stress, on both.

Not here either, outside the family:

- a String the boxed slot was copied into and that is no local or instance variable: `m = [pick(0), 0]; m[0][1..2] = "-"`, a Hash's value, a global, a constant, an `attr_reader`. It is still not written, as for an Integer key (`m[0][1] = "-"` prints `"abcdef"` too). A second name, `b = bx(s); b[1..2] = "-"`, changes the box's own copy. `s[1..2] += "z"`, a Float Range and `s[1..2], x = "-", 1` are as on master.
- a value that is no String: `s[1..2] = 5` gives `"a5def"` and `nil` gives `"adef"` where CRuby raises TypeError. Master went on with `"abcdef"`; `s[1] = 5` gives `"a5cdef"` there.
- two stores that raised the TypeError now run into faults master has under `SPINEL_GC_STRESS=2`. `a[1..2] += [5]` is right plain and at stress 1 and raises a RangeError of freed bytes at 2: the op-assign does not hold its key across the read (`h[k * 1] += [5]` on a boxed Hash stores under freed bytes on master). `a[1..2] = (3..4)` raises the "can't store Range" above and aborts at 2, as `h[1..2] = (3..4)` on a boxed Hash beside a Struct does on master.

With no class in the program, also as on master: a Range key into a boxed Hash is dropped in silence, and into a boxed nil or Integer the program goes on (NoMethodError in CRuby).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
