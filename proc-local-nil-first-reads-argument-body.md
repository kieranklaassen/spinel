## What this changes

```ruby
h = nil
h = ->(x) { x * 2 }
p h.call(1.5)
```

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
-3.0
+0
```

and with `->(s) { s.length }` called on `"wxyz"`

```
spinel diff: exception-diff
  exception (ruby):   (none)
  exception (spinel): NoMethodError: undefined method 'length' for an instance of Integer
```

A local that holds nil as well as the proc is a boxed slot, and the site loop of `infer_block_params` types a literal's parameters only for a receiver it knows as a Proc. The parameters kept the Integer default and read the argument's word through it: a Float read 0, `s.size` on a String answered 8, and most other methods raised NoMethodError. The same literal in a local written once was right.

The loop now takes such a local too, and `cs_type_proc_site` an arm of a conditional the local is written with (`f = on ? ->(s) { ... } : nil`), where the proc stays with its name: every read of the local is the receiver of `call`, `()`, `yield`, `===`, `nil?` or `!`, or a condition, and no write of it is the value of something else. The calls through the name are then all the calls there are.

Not changed, with master's C: a proc that is copied to a second local (`g = f`), stored, answered or handed to a method, one called as `f[x]`, and `f = on && ->(s) { ... }`, `f = nil || ->(s) { ... }`, a `begin ... rescue` value, a global, an instance variable.

One cost. A callback fed its own result (`t = f.call(t)`) is handed a boxed value, so its parameter is boxed. With `s + "!"` that is `exception-diff` (TypeError) on master and with `s * 1.5` it prints 6.0 for 6.75; with `s + 1`, which was right, a call is 113 instructions against 74 (callgrind). The call site is the same in the three. Every other callback called with Integers keeps master's C.

On master b44861f8: `make cident` reports 6,353 identical, 1 differ, the new test. Of 1,225 programs (generated forms, attack programs, 612 callbacks called with Integers) run against CRuby 3.3.6, plain and under `SPINEL_GC_STRESS=1` and `2`, on master 8684d54c: the 904 that are right on master are right here, 873 of them with master's C; 264 that raise, crash or print a wrong answer on master are right; 57 are as on master. None takes more rounds than 9, as on master.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6, the one at hand; nothing in the test differs between the two)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
