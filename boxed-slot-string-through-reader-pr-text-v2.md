Title: A String changed in place through a boxed slot's reader reaches the slot

## What this changes

```ruby
S = Struct.new(:x)
c = S.new
c.x = +"q"
c.x << "z"
p c.x
```

prints `"qz"` in CRuby and `"q"` on master (4d56c1573). The member holds nil as well, so its slot is boxed, and a plain String in a box is a value: `<<` answers a new String, which the statement dropped. An `attr_reader`'s ivar filled after `new(nil)` loses the append the same way, and so do `<<` chains, the bang methods (`upcase!`, `sub!`, `tr!`, ...) and `replace`.

The fault is older than #7462: of 210 measured programs this makes right, 110 lost the change before it as well; the other 100 did not compile then and lose it since. Since #7517 a bracket write through a boxed receiver fills such a slot too, and the append after it is lost the same way where it raised NoMethodError before:

```ruby
S = Struct.new(:x, :n)
c = S.new(nil, 1)
a = [c, 1]
a[0][:x] = +"r"
c.x << "z"
p c.x
```

prints `"rz"` in CRuby and `"r"` on master; it prints `"rz"` here.

For a boxed local or ivar the new String is stored back into the variable (`poly_shl_root_slot`, `emit_face_str_bang`, the `replace` arm of `emit_poly_call`). The reader call of a boxed slot, emitted as the field itself (`call_is_field_read`) on a local, an ivar or self, names a slot the same way: it is read without effect and can be stored to again, so those three sites now take it as they take a variable. A value type's field belongs to a copy of the object and is left alone, and so is a reader the program wrote by hand.

**Checked** on 4d56c1573 with gcc, against CRuby 3.3.6 run with `--enable-frozen-string-literal`, each program at `SPINEL_GC_STRESS` unset, 1 and 2; the new test again under CRuby 4.0.7:

- 864 programs (a Struct, a `keyword_init` Struct, a Data, an `attr_accessor` and a hand-written reader, the slot filled with nil, an Integer or a Symbol as well as a String; eight changes; at the top level and in a method): 654 byte-identical C; 210 differ, each wrong on master and right here (`<<`, `<<` twice, `<<` under a guard, `upcase!`, `replace`: 42 each). On c6bbdfbc9, 110 of the 210 were wrong and 100 a C error.
- 1,722 programs (seven ways the slot comes to be boxed, six receivers, 41 changes): 1,386 byte-identical C; 336 differ:

  | 4d56c1573 | this branch | programs |
  |---|---|---|
  | wrong | right | 232 |
  | right | right, C differs | 59 |
  | NoMethodError | NoMethodError (`reverse!`, `slice!`) | 24 |
  | C error | C error | 8 |
  | wrong | wrong, another line | 13 |

  No program right on 4d56c1573 is wrong on this branch, and no C error or raise becomes an answer. 12 of the 13 keep the String under a second name (`t = c.x; t << "z"; c.x << "y"`): `c.x` takes its own append now, `t` is still a copy.
- `tools/cident.sh 4d56c1573` (test/, benchmark/ and packages/*/test; optcarrot was not in the corpus where this was measured): 6118 identical, 5 differ, 0 refusal changes. The 5 are the new test and four tests that pass before and after: `attr_or_write_slot_kinds`, `attr_or_write_unset_slot`, `nil_narrowing_builtin_names`, `user_dup_clone_freeze_owned`. Each appends to an Array through a boxed slot's reader and takes the store-back's test.
- That test is the cost: the receiver kept in the frame, one tag compare and a branch not taken unless the box holds a plain String, as a boxed local or ivar already pays. `c.x = [1]` and 300,000 times `c.x << i` is 10,217,186 instructions before and 12,617,178 after (callgrind): 8 per append.
- `tools/refusals.sh`: pass (426 records). `make reject-test`: pass.

**Left alone**, each as on master:

- The String read out of the slot into another name or handed to a method that appends (`t = c.x; t << "z"`, `app(c.x)`) is still a copy. Making it the slot's String is a sharing rule, and none is added here.
- A receiver that is no local, ivar or self (`a[0].x << "z"`, `w.c.x << "z"`, `get.x << "z"`) and a reader written by hand (`def x = @x`). `a = [S.new, 1]; a[0][:x] = +"q"; a[0].x << "z"; p a[0].x` prints `"q"` on master and here.
- `c.x.concat("z")`, `prepend`, `setbyte`, `reverse!` and `slice!` raise NoMethodError.

No function over 1,000 lines grows: `emit_poly_call` 918 to 916, `emit_face_str_bang` 54 to 52; `emit_call_body` is untouched.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7: the 14 lines are equal)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (nothing)
