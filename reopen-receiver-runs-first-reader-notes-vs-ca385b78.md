For the reader of the receiver-first head `47ba90fb3da9` (its hand-over is the comment just above this one). Written 15:20 UTC 2026-10-08. Four things: what `arg_runs_nothing` admits, entry by entry; the doors of the same kind, walked once (the coordinator's note of 14:07 UTC); one program per kind of receiver for `recv_held_as_read`; and the delta against `ca385b78c482`. Every cell below is the bare `f6b2744b27d8` against this head, both built fresh, gcc and clang; "the bare tip's C" means `spinel -c` writes the same bytes on both. Each sha256 is of the block's text with one final newline.

**1. What `arg_runs_nothing` admits** (src/codegen_call.c; a whitelist that walks the argument itself: a node it does not name is asked of master's `subtree_is_pure_read`, which answers 0 for a write, a `yield`, a block, a lambda, a `defined?`, an operator-assign, a conditional, a splat and every other kind).

- No node (`n < 0`): a parameter with no default, an absent child. Nothing is evaluated.
- A leaf master's `subtree_is_pure_read` admits: a read of a local, an instance variable, a class variable or `self`; an Integer, Float, `nil`, `true`, `false` or Symbol literal; a constant the program defines whose static is plain. Each reads a slot.
- `NK_GlobalVariableReadNode`, `NK_StringNode`: a read of a global's static; a String literal.
- `NK_CallNode`: only where master's `subtree_is_pure_read` admits the whole call (a typed Array's `[]` with an Integer index, a scalar operator by `call_is_scalar_op`, a plain field read that does not allocate by `call_is_field_read`), AND the name is not one the program gave the receiver's builtin class itself (`comp_builtin_kind_reopen_mi`: Integer, Float, String, Symbol, Array, Hash), AND, for an operator, the receiver is an Integer or a Float and every operand is an Integer or a Float (a boolean receiver, and an object, a boolean or any other operand, answer 0). Then its receiver and arguments are walked the same way.
- `NK_AssocNode`: only where the key's type is String, Symbol or Integer; then key and value are walked.
- `NK_EmbeddedStatementsNode`, the `#{...}` of an interpolation: only where the value embedded is a String, an Integer, Float or Symbol whose class the program has not given a `to_s`, or a boolean (row d12 below); then what is inside is walked.
- `NK_ParenthesesNode`, `NK_StatementsNode`, `NK_ArrayNode`, `NK_HashNode`, `NK_KeywordHashNode`, `NK_RangeNode`, `NK_InterpolatedStringNode`, and a call's argument list: made of their children, admitted where every child is.

**2. The doors, walked once** (`doors.rb` below holds the 23 programs; each is `puts cur.pair(ARG)` with `def cur = $s`, `$s = +"ab"`, a `pair` added to String that takes a rest, and the program's code under test appending "c" to `$s`, so CRuby prints `abc|1` where that code runs after the receiver is read as one object).

| door | program | the walk | cells |
|---|---|---|---|
| the `hash` of a key that is the program's object | e1, e2 | NOT admitted (the key is no String, Symbol or Integer). `ca385b78c482` admitted it: the first loss | the bare tip's C; `abc|1` on both, gcc and clang |
| `[]` the program gave Array | e3 | NOT admitted (the name is the program's on that builtin). `ca385b78c482` admitted it: the second loss | the bare tip's C; gcc `abc|1`, clang `ab|1` on both |
| `==` or `<=>` on an operand that is an object (`5 == o`, `1.5 == o`, `1 <=> o`) | d1, d10 | NOT admitted (the operand is no Integer or Float). `ca385b78c482` admitted `==`: the third loss, found by this walk | the bare tip's C; gcc right, clang `ab|1` for `==` on both |
| `coerce` on an operand (`5 + o`) | d2 | not admitted, then or now: the result is no scalar, so master's predicate answers 0 | the bare tip's C; right on both |
| `to_s` or `inspect` behind an interpolation of a non-scalar (`"#{o}"`, `"#{[o]}"`) | d5b, d5 | not admitted: an interpolation embeds only a String or a scalar | the bare tip's C; right on both |
| a scalar's own `to_s` behind an interpolation (Symbol, Integer) | d16 | not admitted: the program gave the class a `to_s` | the bare tip's C; the same answers on both |
| `method_missing`, `respond_to_missing?` on an argument's receiver (`o.name`) | d4 | not admitted: the call is no field read | the bare tip's C (NoMethodError on both: Spinel does not run `method_missing` here) |
| a left-out default that calls (`def two(a, b = bump)`, `cur.two(1)`) | d6 | not admitted: a default goes through the same walk, and a call that is no pure read answers 0 | the bare tip's C; gcc right, clang `ab|1` on both |
| a Hash with a default block (`h[:k]`) | d7 | not admitted: an index of a Hash is no typed Array index | the bare tip's C; right on both |
| a reader a subclass overrides (`o.name`, `o` of two classes) | d11 | not admitted: no plain field read | the bare tip's C; right on both |
| `[]` of an Array subclass | d13 | not admitted | the bare tip's C; gcc right, clang `ab|1` on both |
| a redefined `Integer#+` (`x + 1`) | d15 | not admitted (the name is the program's on Integer) | the bare tip's C; gcc right, clang `ab|1` on both |
| a boolean's own `&`, and `==` given to Object, on a boolean (`t & true`, `t == 1`, `1 == t`) | d3, d14 | not admitted now (a boolean receiver or operand); `ca385b78c482` admitted them | the bare tip's C; Spinel runs none of them: `ab|1` on both, gcc and clang (CRuby runs each) |
| a redefined `hash` and `eql?` on String, Symbol or Integer keys | d8, d8b | ADMITTED: Spinel's Hash literal calls neither (CRuby calls neither for these three) | the C differs; `ab|1`, `ab|2` on both, as CRuby |
| a Range literal over values with their own `<=>` or `succ`: Strings, Floats, Integers | d9, e4, e5 | ADMITTED: Spinel's Range literal holds its two bounds and calls nothing (a Range of the program's objects is refused at compile time) | the C differs; `ab|1` on both in every cell. CRuby runs a redefined `Float#<=>` (`abc|1` for e4): wrong on master and here alike, a side find |
| a boolean's own `to_s` behind an interpolation (`"#{t}"`) | d12 | ADMITTED: `comp_builtin_kind_reopen_mi` knows no boolean class, and Spinel's interpolation does not call a redefined `TrueClass#to_s` | the C differs; `ab|1` on both in every cell (CRuby `abc|1`): wrong on master and here alike |

No door's cell differs between the bare tip and this head. The three ADMITTED rows are the ones a reader may want to turn round: each is admitted because Spinel runs none of the program's code there, on master as here, and I probed that, not read it off the source.

**3. `recv_held_as_read`: one program per kind** (`gen_kinds.rb` below; each is `puts recv.pair(arg); p $log` where `recv` logs and answers the kind's value, `arg` logs, appends "c" to the global String `$s` and answers 1, and `pair` is added to the kind's class). Plain and at `SPINEL_GC_STRESS=2`; "right" is CRuby 3.3.6's output in both runs.

Held first (the C differs from the bare tip's; the receiver's call now runs ahead of the argument's with gcc):

| kind | receiver | bare gcc | bare clang | head gcc | head clang |
|---|---|---|---|---|---|
| Float | `2.5` | wrong (`["arg", "recv"]`) | right | right | right |
| Symbol | `:s` | wrong | right | right | right |
| Range | `(1..3)` | wrong | right | right | right |
| Array (its pointer) | `[1, 2]` | wrong | right | right | right |
| Hash (its pointer) | `{ 1 => 2 }` | wrong | right | right | right |
| a String no other name holds: an interpolation | `"a#{ARGV.size}"` | wrong | right | right | right |
| the same: a builtin's own new String | `$s.upcase` | wrong | right | right | right |
| the same: an Integer's `to_s` | `ARGV.size.to_s` | wrong | right | right | right |
| the same: a method that ends in one and has no `return` | `fresh` (`def fresh = "f#{ARGV.size}"`) | wrong | right | right | right |

Listed by `recv_held_as_read` but with the bare tip's C in this shape: an Integer (`5`: right in the four cells on both), an object of the program's reaching `Object#pair` (`Foo.new`: right on both), `true` with `TrueClass#pair` (wrong on both, the same output: `["arg", "recv"]`).

Left as master's C (a String another name may hold, or a boxed value; the C is the bare tip's byte for byte, so each cell is the bare tip's cell):

| kind | receiver | bare gcc and head gcc | bare clang and head clang |
|---|---|---|---|
| a global | `$s` | `String\|3\|1`, `["arg", "recv"]` | `String\|2\|1`, `["recv", "arg"]` |
| a method that answers its parameter | `same($s)` | the same two | the same two |
| a reader's instance variable | `$box.s` | `String\|2\|1`, `["arg", "recv"]` | `String\|2\|1`, `["recv", "arg"]` |
| a method with a `return` of the global | `early` | as the global | as the global |
| a local changed in place for a receiver | `(t << "1").pair(add(t))` | `abc1\|1` | `ab1\|1` |
| a boxed receiver (a String or an Integer) | `recv(ARGV.size)` | `ab\|1` | `ab\|1` |

CRuby prints `String|3|1` and `["recv", "arg"]` for the first four, `ab1c|1` for the local and `abc|1` for the boxed one, so each of these is wrong on master in one way or the other and wrong here the same way: with gcc the argument's call runs first and the String read is the longer one; with clang the receiver's call runs first and the String it answered is read as it was. Holding the receiver first would turn gcc's cell into clang's, which is the loss the first mend closed for a program that prints only the String (`cur.pair(add)` in the test).
