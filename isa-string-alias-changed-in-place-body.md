<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

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

Of 4,535 programs (the boxed value held nine ways, nine guards, the local named five ways and changed nine ways, 35 later uses of it), the C changes for 1,714, and none of those was right before. 1,069 become right (1,065 printed a wrong line, four were refused). 645 print a wrong line: 631 print the line master prints for the same program under `case e when String`, where the append is lost further on (a Hash's value block, a value a method returned, a constant handed to the method, two names chained outside a block), and 14 ask `t.equal?(e)`, whose argument is still the narrowed read. With `--share-strings` 1,686 go from wrong to right, the 14 `equal?` rows stay wrong, and 14 that call `t.each_char` with a block stop at the C error master has for the `when` arm. `tools/cident.sh`: 6400 identical, 1 differ (the new test); with `--share-strings` 6288 identical, 1 differ, 112 refused by both.

Four of the 645 were refused before: `t = e; t << "z"; $acc << t` in a method handed a constant. t was a String variable pushed into a global and master refuses that; boxed, it is not one, the program builds, and the constant misses the append exactly as it does under `when String` on master, where the C is the same but for the guard's test.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [x] Depends on: # (nothing)
