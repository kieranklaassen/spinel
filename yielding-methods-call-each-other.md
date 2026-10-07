<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def ea(n)
  if n == 0
    yield 0
  else
    eb(n - 1) { |v| yield v + 1 }
  end
end
def eb(n)
  if n == 0
    yield 0
  else
    ea(n - 1) { |v| yield v + 1 }
  end
end
p ea(5) { |v| v * 2 }      # 10 in CRuby
```

On master the compiler dies of a segmentation fault. Whether a yield's Integer or Float value can be nil is asked of the blocks at the method's call sites, by the tail of each (`nullable_int_value`). Here such a tail is the other method's yield, whose blocks end in this method's yield again, and the two were asked about each other until the stack ran out.

A method whose yield is being asked is now not asked again. The second asking has no tail the first does not see, so the answer is the same.

Tests: `test/yielding_methods_call_each_other.rb` has two and three such methods, at the top level and in a class, with an Integer, an Integer that may be nil and a Float; master's compiler crashes on it.

Generated C against master (`make cident REF=8578e3fb`): `6354 identical, 0 differ, 1 refusal changes` (the new test, on which master's compiler crashes). `tools/refusals.sh` passes (534 records). optcarrot's generated C is byte-identical. Programs, with CRuby 3.3.6 as the reference: 160 (eight shapes of one to three methods, five block values, four uses of the result). The 64 that crash the compiler are right. The other 96 are the same: 36 right, 20 refused by name, and 40 whose C does not build on master, a String value among them.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Integers, nil, Floats and an Array of Floats)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
