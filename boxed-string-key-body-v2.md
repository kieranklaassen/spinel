<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
b = [+"abc", 1][0]
b["b"] = "x"; p b       # CRuby "axc"; here "abc"
b["q"] = "x"            # CRuby IndexError, string not matched; here nothing
a = [+"abc", 1]; k = ["b", 1][0]
a[0][k] = "x"           # CRuby "axc"; here TypeError, no implicit conversion of String into Integer
```

A boxed receiver's `recv["key"] = v` goes to `sp_poly_set_str`, which stores into a Hash or an OpenStruct and answers for anything else; with the key boxed it goes to `sp_poly_set_poly`. The compiler's own String arm, for a receiver it knows, was right.

Both calls now pass a String receiver to one `sp_poly_str_aset`: the first occurrence of a String key is replaced, a key that is not there is IndexError "string not matched" ahead of a frozen receiver's FrozenError as in CRuby, and an Integer key replaces one character as `sp_poly_slot_set_key` already did. The new contents are stored back where the Integer key's arm stores them: into a local or an ivar, or into the slot of an `outer[i]` receiver whose outer is an Array or a Hash. A String two names hold takes them in place. Every other receiver goes on to `sp_poly_set_str` and `sp_poly_set_poly` unchanged. `lib/spinel_rt.h` only gains lines.

A boxed Hash pays for the look at its receiver: 182 instructions a `h["k"] = i` before, 194 after; 140 and 150 with the key boxed (callgrind, 200,000 stores).

The generated C changes in the new test and in 30 existing tests that write `recv[key] = v` on a boxed receiver with a String or a boxed key (`sp_poly_set_str(x, ...)` becomes `x = sp_poly_aset_str(x, ...)`); each of the 30 prints what it printed. No benchmark and not optcarrot.

Left as it is:

- A boxed String that is neither a local, an ivar nor such a slot (a global, a method's answer, the element of a boxed outer) still keeps its old contents, with an Integer key as with a String one.
- A value that is no String: `x["b"] = 5` now prints "a5cabc" where CRuby raises TypeError, as master's `x[1] = 5` does; master left the String as it was.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
