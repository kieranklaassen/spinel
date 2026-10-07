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

- 1,296 programs (beside a class of the program's and beside a Struct; an Array of Integers, of Strings and mixed, a String, a frozen String, a frozen Array, a Hash, nil and the class's own object as the receiver; in a local, an instance variable, an element and a parameter; nine Ranges, `1..2`, `1...3`, `2..`, `..1`, `-2..-1`, `9..10`, `-9..1`, `i..j` and a boxed one; a value that fits and one of another kind): 800 made right, 178 right on both, none lost. The other 318 are under "Not here".
- `make cident`: the generated C of the corpus is unchanged; the two new tests are the only programs whose C differs.
- callgrind, a million stores beside a class that owns `[]=`: an Integer index into a boxed Array 119,676,526 to 119,676,757, into a boxed String 1,327,605,421 to 1,327,604,479, into the class's own object 39,668,704 to 39,668,917; a String key into a boxed Hash 209,674,348 to 207,674,534; a boxed key with no class 94,673,443 to 94,673,494. No store pays an instruction.

Not here, the 318, each the same output on master unless said:

- a Hash receiver (140): a Range key into a Hash typed with String keys stays the loud "cannot store a Range key ... (the hash was not widened for this store)";
- the class's own object (144): a Struct given a Range key raises NameError, no member '..1' in struct (TypeError in CRuby), and `p((x[..1] = :v))` on the class's object prints what its `[]=` returns, not `:v`;
- an Array of Strings spliced past its end (16): CRuby pads with nil; master raised the TypeError above, this branch raises the loud "can't store NilClass in an Array of String through a boxed receiver";
- a frozen String in a local or an instance variable given a Range that starts outside it, `9..10` or `-9..1` (16): CRuby raises RangeError; master went on in silence, this branch raises FrozenError;
- a boxed key that holds a Range, on a String in an instance variable (2): right in a plain run, aborts under stress, on both.

With no class in the program, also as on master: a Range key into a boxed Hash is dropped in silence, and into a boxed nil or Integer the program goes on (NoMethodError in CRuby).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
