<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
class Box; attr_accessor :x; end
r = Box.new
r.x ||= +"ab"
r.x << "z"
p r.x
```

With `--share-strings` master prints `"ab"`; CRuby and this print `"abz"`. (`spinel diff` takes no compiler flag; for the default build it reports the same two lines.) Written `r.x = +"ab"` it is right under the flag.

A slot that also holds nil is a box, and under the flag each String written into a shared box is boxed as its handle (`share_lift_poly_ivar_stores`). The writes listed there were `@x = v`, the attribute writer and `instance_variable_set`. `o.x ||= v`, `o.x &&= v`, `@x ||= v` and `@x &&= v` store through the same `emit_boxed` and were not listed, so they stored a copy; a Struct member's `||=` lost the append the same way. The share walk also asked a CallOrWriteNode for `read_name`, a field the parser does not write (the reader's name is `name`), so `(r.x ||= +"ab") << "z"` did not make the slot shared. Both places are read only under the flag: it completes the flag's own listing and adds no sharing rule.

Of 2,266 programs around an attribute `||=` / `&&=` (attr_accessor, a subclass, a module, a Struct member, `self.x`, `&.`; fourteen kinds of value; a slot that also holds another kind), the default build's generated C is the same for each of the 2,136 that build, and the other 130 are refused in the same words. With the flag 111 go from wrong to right, 14 that raised NoMethodError at run time are right, and none that is right changes. 10 that print a wrong answer on master are refused: `r.x ||= [+"a"]` followed by `r.x.last << "!"`, in the flag's sentence for a typed String container, as the `=` form is on master.

## `make gate` (on this branch merged with current master)

```
not run in full here (it runs on the Mac before anything goes upstream). In the cloud, on this commit alone on master a39414338: make share-strings-test passes; tools/gate.rb check passes (no Ruby 4.0 here, so .expected was not compared).
cident: 6366 identical, 4 differ, 0 refusal changes, 0 refused by both, 0 not in the reference (against a39414338): the four that print the compiler's revision.
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; it prints twelve Strings)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
