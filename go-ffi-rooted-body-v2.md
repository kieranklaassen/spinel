<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A C function called with a shared String handle beside another argument that allocates gets a freed String. It shows under `SPINEL_GC_STRESS=2`. The fix costs 19 to 37 instructions a call where it applies, and one call that was right pays it: `LibC.strcmp(s, a.get)`, below.

```ruby
module LibC
  ffi_func :strncmp, [:str, :str, :int], :int
end
s = +"12"
t = s
t << "345"
p LibC.strncmp(s, t, s.size + 0)     # master at SPINEL_GC_STRESS=2: 170. CRuby's answer: 0
```

A String held as a handle goes to a `:str` argument as a copy when another operand of the call runs code, and that copy is held by nothing but the C call's argument list: the second copy's allocation collected the first. Two handles are not the only case. One handle beside a call that builds a String (`LibC.strncmp(s, joined(x, "345"), 5)`) answered -170 the same way, with clang so did a handle beside an Integer argument that allocates on its way, and so did the Strings handed to a variadic function (`LibC.printf("%s %s\n", s, joined(x, "345"))`).

`emit_call_cmethod_arms` (`src/codegen_call_class.c`) rooted the String arguments only where the call can run Ruby code. It now roots each String made where it stands in the call when another argument's evaluation allocates (`ffi_str_arg_beside_alloc`): in its temp where the call already takes the temp form, else in a slot the argument is assigned to in its own place (`ffi_arg_hold`). No argument moves, so the arguments run in the order they ran in, with gcc and with clang.

An argument the operand order ran ahead of the call, a read of a value its owner holds (a typed Array's element, a plain reader, a Hash's value, a length: `operand_is_held_read`) and a handle's read that hands C the live buffer are neither made here nor allocating. Those calls keep their C: two elements, two readers, two Hash values, a handle beside an element, a reader or a length, two locals.

Cost, by callgrind on master 8dc55225, instructions a call over 1,000,000 calls, gcc and clang: `LibC.strcmp(s, u + v)` 27.8 and 33.8; `LibC.strcmp(s, joined(u, v))` 25.8 and 36.8; `LibC.strncmp(s, t, s.size)` 18.9 and 26.9. Those three were wrong under stress. `LibC.strcmp(s, a.get)` with `def get; @name; end` was right, and pays 28.0 and 32.0: a user method counts as allocating everywhere in the emitter, and nothing says this one builds nothing.

`tools/cident.sh` against that master: 6,445 identical, 2 differ, 0 refusal changes, of 6,447: this test and `test/ffi_str_borrow.rb`.

`test/ffi_str_borrow.rb` fails under stress on master for this cause; it joins `GC_STRESS_TESTS` with the new test.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
