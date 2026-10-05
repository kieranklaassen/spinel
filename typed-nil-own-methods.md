<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
class C
  def opts = (@opts ||= {a: 1})
  def pairs = @opts.to_a
end
p C.new.pairs             # [] in CRuby, SIGSEGV here
```

A nil in an Array, a Hash, a String or an object slot is a NULL pointer, and a method nil has of its own was answered for the slot's type without a look at the pointer. dd985dee did `class`, `to_s` and `== nil`; 4dc7bcdc did the nil-only names for an Integer or a Float slot. These are the names left for a slot whose nil is NULL. Three commits, a cause each, the crash first; each stands alone on master. A fourth keeps the second from slowing the compiler.

**1. to_a and to_h on a nil in an Array or a Hash slot answer [] and {}** (a70d4deb)

The typed emissions read the NULL or answered it: `Hash#to_a` read its `len` (SIGSEGV), `Array#to_a` and `Hash#to_h` are the receiver itself (nil for [] and {}), `Array#to_h` boxed the NULL and raised, `Array(x)` handed a typed Array on as it is. The receiver is read once into a temp; NULL answers nil's value in the call's own type, anything else goes through the emission it had. Only a call the program wrote as `to_a` or `to_h` is tested: the `to_a` the analysis writes for `entries`, or puts under `each_slice`, `cycle` and others, stands for a method nil lacks.

**2. A nil in a String or an object slot answers to_a, to_h, &, | and ^** (255cf39a)

```ruby
class Card
  def name = (@name ||= +"s")
  def tags = @name.to_a
end
p Card.new.tags           # [] in CRuby, NoMethodError here
```

String and a class of the program's own have none of the five, Hash has no `&`, `|` or `^`, Array no `^`. No arm answered such a call, so it stayed untyped and raised whatever the slot held. `infer_last_resort_call` types it as the boxed value nil gives; the emission tests the slot: NULL answers [] or {}, false for `&`, the argument's truth for `|` and `^`, and any other value raises the NoMethodError it raised, with the same name, arguments and receiver. A class that has the method keeps it, as does a program that defines it on NilClass.

**3. is_a? on a nil in an Array or a Hash slot answers for nil** (1be0f59c)

`@list.is_a?(NilClass)` printed false and `@list.is_a?(Array)` true for a nil: `is_a?`, `kind_of?` and `instance_of?` were folded from the slot's type. A String slot already reads its NULL there; an Array or a Hash slot takes the same test.

**4. A nil-only operator in another's operand is probed once** (b489211a)

The second commit emits a call once to see that the gate's raise is what answers it, and takes that back. A call in the operand was probed again by each emission of the call around it, so `s | (s | (s | t))` on String slots doubled the compile time a level: eighteen levels took 4.7 s, for 0.018 s on master. What the probe saw is kept by node; eighteen levels take 0.013 s. The generated C does not change: `make cident` against the third commit reports `6026 identical, 0 differ`, and the 7,392 programs below are byte for byte the same.

**Measured.** 7,392 generated programs: 22 methods on six kinds of slot (Array, Hash, String, Integer, Struct, a class of the program's own), the nil reaching the slot seven ways (an instance variable not assigned yet, an `attr_reader`, a method's value, a parameter whose default is nil, an Array's element, a Hash's miss, a local), the call as a statement, a value, an argument and in an interpolation; each program with a twin whose slot holds a value. Master ab9b925a against the three commits, gcc, plain and under `SPINEL_GC_STRESS=1` and `2`, CRuby 3.3.6 as the reference:

| | master | here |
|---|---|---|
| nil programs right (of 3,696) | 2,782 | 3,237 |
| SIGSEGV | 172 | 160 |
| raise where CRuby answers | 572 | 212 |
| wrong answer, nothing said | 170 | 87 |
| twins with a value in the slot (3,696) | | each prints what it printed |

455 programs become right: 48 by the first commit, 344 by the second, 63 by the third. None that is right on master is wrong, refused or non-building; none that crashed, raised or did not build answers wrongly now.

**Not covered**, and as on master:

- `to_i` and `to_f` on an Array, a Hash or an object slot (raise); `dup`, `clone` and `frozen?` (SIGSEGV or false); a Struct's own `to_a`, `to_h` and `hash`, and `to_h` with a block on a nil Hash slot (SIGSEGV).
- Array's own `&` and `|` on a nil Array slot: with an Array operand they answer as an empty Array does (`[]` for false, the operand for true); any other operand raises TypeError.
- A class test that guards a read of the slot, `x.is_a?(Array) ? x.size : -1` on a local or `return 0 unless x.is_a?(Array)` on a parameter: the condition is folded from the slot's type and the guarded branch reads the NULL (SIGSEGV). `Array === x` and `case`/`when` are answered for the slot's type.
- `x.method(:to_a).call` (nil for []); the nil-only names on an Integer instance variable filled by `||=` (raise).

**Cost.** A `to_a`, a `to_h` or an `Array()` on an Array or a Hash that is not a literal gains one test, two to eight instructions a call. It is seven where master's loop had folded the conversion away: `t += a.to_a.size` on a local Array, four million turns, takes 52,657,680 instructions for 24,657,660. It is two where it had not: four million calls on locals take 52,658,878 for 44,658,843, and 4.2 million through a method reading an instance variable take 172,582,459 for 146,182,444. The test stands in front of those written calls and the class tests only; no benchmark's generated C changes.

**Generated C.** `make cident REF=upstream/master` on 3a95d7dd: `5865 identical, 160 differ, 0 refusal changes` for the first three commits; the fourth adds its test and changes no other program. The 160 are the three new tests and 157 programs: 139 gain the first commit's test at a `to_a`, a `to_h` or an `Array()`, 17 the third's at a class test, and in one (`array_operator_non_array_type_error.rb`) `list | extra` with a String operand is typed as the boxed value its TypeError arm emits. The 160 pass. optcarrot's generated C is byte-identical.

**Tests.** `test/nil_array_hash_slot_to_a_to_h.rb` (SIGSEGV on master), `test/nil_slot_nil_only_names.rb` and `test/nil_slot_nil_only_nested.rb` (NoMethodError on master), `test/nil_array_hash_slot_class_test.rb` (wrong lines on master). Each passes with gcc and clang, plain, under `SPINEL_GC_STRESS=1` and `2`, and under `SPINEL_GC_MINOR=1 SPINEL_GC_VERIFY_GEN=1`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the four are equal under Ruby 4.0.7)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
