## What this changes

```ruby
K = Integer
p 7.is_a?(K)   # false; CRuby prints true
```

`is_a?`, `kind_of?` and `instance_of?` read the argument's name, and `K` names no class: the three answered false for a constant holding a builtin class or module, a class of the program's own, a Struct or an exception class, on a typed and on a boxed receiver, so `raise TypeError unless v.is_a?(K)` raised. `K === 7` and `K.new` were right, because `rewrite_const_alias_receivers` rewrites a receiver's name to the class the constant holds. It now rewrites the argument of the three too, and the C is the C of the call written with the class.

It does so only where the constant holds that class when the call runs and the read names that constant: the program writes it once, as a statement `K = C` or `K = Mod::C` with `Mod` its own; the read sits in a later statement, or in a method body when no method of the program can run before the write; and the read is `::K`, `Mod::K` for the body that wrote it, or a bare `K` at the program's level or inside that body. Inside a class CRuby looks a bare name up in what the class inherits or mixes in before the program's level. A body brings no constant of CRuby's or a library's only where it reopens no namespace that holds some and what it inherits or mixes in is a builtin with none (`bc_builtin_constless`, the list `refuse_unreachable_bare_constants` asks) or a class or module the program defines that no library names (`bc_toplevel_known`); where one body of the program is not such (`module Process`, `include Math`, `< Socket`), a bare read in another body than the write's is left. A write's value is read where and when the write stands: the class's definition must be a statement before it, one a bare name finds from there or in the top-level body a path (`K = Lib::C`) names, since elsewhere a `const_missing` of the program answers the name with whatever it returns. By the same lookup `ERR = DomainError` under `include Math` holds Math's, so where a body may read CRuby's constants first a bare value is taken at the program's own level alone. A file required inside a def, a block or an expression is spliced ahead of that statement and loads when the require runs; the parser marks the statements of such a file (`req_late`, set beside `req_pop` by a helper, so `flatten_node` does not grow) and its constant writes are left.

Not here: a constant written twice, `K ||= C`, `Mod::K = C`, a multiple assignment, `K = 5.class`, `J = K`, a builtin namespace's class (`K = File::Stat`), a value by a longer path or through a parent's body (`K = A::B::C`, `K = Sub::C` for a `C` of `Sub`'s parent), a class of a library the compiler loads unasked (`K = Set` with no `require "set"`), a write under a condition, a write in a file required inside a method or a block, a class opened twice (`class K` under a module reopens the class another body's constant `K` holds), a constant named by `const_set`, `private_constant` or `remove_const` (through `send` too), a program that defines `is_a?` itself or a class under `BasicObject`, a program that sends or defines a method by a name no literal spells (`send(m, ...)`, `define_method(n)`) or sets by `const_set` a name it writes no constant of, and a method's read in a program that prints or calls before the constant's write. They answer as before.

Tests: `test/const_alias_is_a.rb`, 28 of its 38 lines missing or different on master; `test/const_alias_is_a_scope.rb`, 2 of 7; `test/const_alias_is_a_late.rb`, 1 of 2. `test/const_alias_is_a_library.rb`, 1 of 2; `test/const_alias_is_a_missing.rb`, 1 of 4. `test/const_alias_is_a_own.rb`, `test/const_alias_is_a_computed.rb` and `test/const_alias_is_a_basic.rb` pin a program with its own `is_a?`, one that defines it under a computed name and one with a `BasicObject` subclass, and pass on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: the pull request "A boxed number is not an instance_of? Numeric"
