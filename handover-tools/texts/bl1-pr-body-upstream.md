## What this changes

```ruby
E = ArgumentError
begin
  raise ArgumentError, "a"
rescue E => e
  puts "got #{e.class}"   # never reached: the exception left the program uncaught
end
```

`rescue E` caught nothing, and `raise E, "a"` raised an exception whose class was named `E`: `rescue ArgumentError` let it through and `rescue => e` printed `E` for `e.class`. After `rescue CE => e` with `CE` a class of the program's, `e` had no type and `e.code + 1` did not build. The rescue and raise emitters read the name in the clause, and `E` names no class.

`rewrite_const_alias_receivers` now rewrites the names of a rescue list and the first argument of a receiverless `raise` or `fail`, under the guards the `is_a?` argument has: the constant holds that class when the clause runs, and the read names that constant. The C is the C of the clause written with the class. The first commit is a refactor with no change in C: the rewrite takes the constant read instead of the `is_a?` call.

Not here: a program that defines `===`, `exception`, `raise` or `fail` itself (rescue and raise ask the class by the first two), a superclass (`class X < K`), `J = K`, and `M = Math; M::PI`. They answer as before.

Tests: `test/const_alias_rescue_raise.rb`, which master refuses to build; `test/const_alias_rescue_own.rb` pins a class with its own `===` and passes on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: the pull request "A constant holding a class names it in is_a?, kind_of? and instance_of?"
