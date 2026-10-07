<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`+=` on a String local that is also appended to is refused, where the same write spelled out compiles:

```ruby
out = +""
out << "a"
out += "b"     # master: unsupported operator assignment
out << "c"
p out          # "abc" in CRuby; with `out = out + "b"` master compiles it and is right
```

A local that is appended to holds its String by a handle, and `emit_op_assign_lv` had an arm for `+=` on a plain String only. The new arm does what the spelled-out write does. String#+ answers a new String, so the local gets a handle of its own and the String its other names hold is not touched (`t = s << "a"; t += "x"` leaves `s` as it was). The operand runs first and the receiver is read after it, it converts by `to_str` or raises TypeError, and a nil receiver raises NoMethodError.

What was chosen: the arm reads the local's slot as a handle, so it applies only where every other write of the local is on a list of writes proven to leave a handle there (`strbuf_value_proven_handle`): nil, a local or an instance variable that holds a handle, an append chain on one, a call on one that answers its receiver, and a String no other name holds (a literal, an interpolation, `x.dup`, `a + b`). Any other write keeps master's refusal, in master's words:

```ruby
$g = +"b"
t = $g << "a"     # $g's own String has no handle to give
t += "x"          # unsupported operator assignment, as on master
```

A handle made there would part `t` from the global, so none is made. The value of the write (`v = (t += "x")`) stays refused too: `v` would have to be the same String as `t`.

Tests: `test/string_appended_local_plus_assign.rb`, 24 lines, which master refuses; four reject tests (the value form, and a first write that appends to a global, a constant and a method's result) with their eight records in `test/collect/refusals.expected`.

Generated C against master (`make cident REF=185c4d66`): 6327 identical, 0 differ, 1 refusal changes (the new test, which master refuses). `tools/refusals.sh` passes (538 records). optcarrot's generated C is byte-identical. Of 696 programs written around the write, the 309 that build on master print the same here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Strings, true and false)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
