<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A C function called with a shared String handle beside another argument that allocates gets a freed String. It shows under `SPINEL_GC_STRESS=2`; 4,000,000 plain calls of two shapes were right.

```ruby
module LibC
  ffi_func :strncmp, [:str, :str, :int], :int
end
s = +"12"
t = s
t << "345"
p LibC.strncmp(s, t, s.size + 0)     # master at SPINEL_GC_STRESS=2: 170. CRuby's answer: 0
```

A String held as a handle goes to a `:str` argument as a copy when another operand of the call runs code, and that copy is held by nothing but the C call's argument list: the second copy's allocation collected the first. Two handles are not the only case. One handle beside a call that builds a String (`LibC.strncmp(s, joined(x, "345"), 5)`) answered -170 the same way, and with clang so did a handle beside an Integer argument that allocates on its way.

`emit_call_cmethod_arms` (`src/codegen_call_class.c`) moved the String arguments to rooted temps only where the call can run Ruby code. It now does so too where a new String sits beside another argument whose evaluation allocates (`ffi_str_arg_beside_alloc`, asking `operand_may_allocate`). A call with one such argument, or with borrowed buffers and literals only, keeps its C.

Cost, by callgrind on master 4f8b737c: 1,000,000 `LibC.strncmp(s, t, s.size + 0)` take 562,135,600 instructions before and 580,995,144 after, 19 a call; `LibC.strncmp(s, "12345", 5)`: the C is identical. `tools/cident.sh` against that master: 6,405 identical, 2 differ, 0 refusal changes, of 6,407: this test and `test/ffi_str_borrow.rb`.

`test/ffi_str_borrow.rb` fails under stress on master for this cause; it joins `GC_STRESS_TESTS` with the new test.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
