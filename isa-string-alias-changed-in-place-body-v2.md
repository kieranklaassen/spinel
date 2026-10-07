<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A fix with a cost, said first. Where a guarded String is changed under a new name and read under no other, the arm now has the C the `when` arm has on master, and costs what that costs. Callgrind, a million calls of `def f(e); if e.is_a?(String); t = e; t.upcase!; return t.size; end; 0; end`, half of them handed a new String: 667,077,888 instructions before, 766,815,195 after (the `when` arm on master: 767,812,935); that is 200 a String, the handle the lift makes. With `t << "z"` for the `upcase!`: 568,848,928 before, 514,489,830 after (the `when` arm: 517,987,289). Whether the caller reads its String again is not known at the guard, so this is not cut.

```ruby
r = [+"ab", 5]
e = r[0]
if e.is_a?(String)
  t = e
  t << "z"
end
p r
```

prints `["abz", 5]` in CRuby and `["ab", 5]` here, with and without `--share-strings`. With `case e when String` in the guard's place it prints `["abz", 5]`.

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-["abz", 5]
+["ab", 5]
```

The guard narrows the reads of `e` in its arm to String, and a narrowed read unboxes: `t = e` took the bytes out of the box, t was a String of its own, and the append grew that one. The `when` arm narrows nothing, so there t is boxed as e is and `lift_poly_alias_reads` makes the two names one String.

`isa_mark_reads` already leaves an Array read boxed where it is handed on, because the narrowed read is a copy. It now leaves a String read boxed where it is the value of a local's assignment and that local is changed in place as a String: itself, under a name it is assigned to (`t = u = e`, `u = e; t = u`), or by a method it is handed to whose parameter is (`add(t)`). The lift then does for the `is_a?` arm what it does for the `when` arm. A local that is only read is assigned the narrowed String as before and keeps its C.

Two kinds of local keep the narrowed read though they are changed in place, and keep their C. One that is the receiver of a call with a block: under `--share-strings` a boxed String's `each_char { }` and `each_line { }` do not build, and its `split(x) { }` raises NoMethodError with and without the flag, while the copy is right for a program that reads the String under that name alone. And one whose guarded value is only what a method of the program returned, read nowhere else (`e = pick(i)`): the box does not reach that String either.

`isa_alias_reaches` reads the writes and the calls of its one scope off their chains, so a guarded assignment costs the size of its scope: `spinel -S` on 1,000 methods that each guard, assign and append takes 8,075,371,614 instructions before and 8,085,647,019 after.

Of 5,095 programs (the boxed value held nine ways, nine guards, the local named five ways and changed nine ways, 35 later uses of it), the C changes for 1,592, and none of those was right before. 1,059 become right (1,055 printed a wrong line, four were refused). 533 print a wrong line: 519 print the line they printed before, where the append is lost further on, as it is under `when` (a Hash's value block, a constant handed to the method, two names chained outside a block); 10 ask `t.equal?(e)`, whose argument is still the narrowed read; and four were refused before (`$acc << t` in a method handed a constant: boxed, t is no longer the String variable that refusal names) and print what master prints for them under `when String`, the constant's lost append, by the same C in the caller. With `--share-strings` the C changes for 1,592 too: 1,578 go from wrong to right and the 14 that ask `t.equal?(e)` stay wrong; none was right before. `tools/cident.sh`: 6446 identical, 1 differ (the new test); with `--share-strings` 6361 identical, 1 differ, 85 refused by both.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [x] Depends on: # (nothing)
