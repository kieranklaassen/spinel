## What this changes

```ruby
K = Integer
p 7.is_a?(K)   # false; CRuby prints true
```

`is_a?`, `kind_of?` and `instance_of?` read the argument's name, and `K` names no class: the three answered false for a constant holding a builtin class or module, a class of the program's own, a Struct or an exception class, on a typed and on a boxed receiver, so `raise TypeError unless v.is_a?(K)` raised. `K === 7` and `K.new` were right, because `rewrite_const_alias_receivers` rewrites a receiver's name to the class the constant holds. It now rewrites the argument of the three too, and the C is the C of the call written with the class.

It does so only where the constant holds that class when the call runs and the read names that constant: the program writes it once, as a statement `K = C` or `K = Mod::C` with `Mod` its own; the read sits in a later statement, or in a method body when no method of the program can run before the write; and the read is `::K`, `Mod::K` for the body that wrote it, or a bare `K` at the program's level or inside that body. Inside a class CRuby looks a bare name up in what the class inherits or mixes in before the program's level, so where the program opens, inherits or mixes in one of CRuby's namespaces that hold constants (`module Process`, `include Math`, `< File`), a bare read in another body than the write's is left. A file required inside a def, a block or an expression is spliced ahead of that statement and loads when the require runs; the parser marks the constant writes of such a file (`req_late`) and they are left.

Not here: a constant written twice, `K ||= C`, `Mod::K = C`, a multiple assignment, `K = 5.class`, `J = K`, a builtin namespace's class (`K = File::Stat`), a write under a condition, a write in a file required inside a method or a block, a class opened twice (`class K` under a module reopens the class another body's constant `K` holds), a constant named by `const_set`, `private_constant` or `remove_const`, a program that defines `is_a?` itself or a class under `BasicObject`, and a method's read in a program that prints or calls before the constant's write. They answer as before.

Tests: `test/const_alias_is_a.rb`, 28 of its 38 lines missing or different on master; `test/const_alias_is_a_scope.rb`, 2 of 4; `test/const_alias_is_a_late.rb`, 1 of 2. `test/const_alias_is_a_own.rb` and `test/const_alias_is_a_basic.rb` pin a program with its own `is_a?` and one with a `BasicObject` subclass, and pass on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: the pull request "A boxed number is not an instance_of? Numeric"
