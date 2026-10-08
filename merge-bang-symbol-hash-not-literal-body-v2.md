<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Cost first: a program that holds such a `merge!` behind a condition, and was run only where the condition is false, was right on master with a typed Hash. Its receiver is now the general Hash, which is what master makes of the same line written with the literal: 200,000 reads after `h.merge!({z: 9}) if c` are 39,268,771 instructions on master, after `h.merge!(m) if c` 39,269,228 here and 19,264,273 on master. A read by a String key goes from 96 to 196 instructions a turn and a store from 107 to 228, and an `each` over four entries from 435 to 167 (callgrind). The kind of a Hash is settled at compile time from the stores the program holds, so no list can tell the run that reaches the call from the run that does not. A call in a method that cannot run changes nothing, and a program without such a call is the C it was.

```ruby
h = {"a" => 1}
m = {b: 2}
h.merge!(m)
p h.to_a
```

```
spinel diff: exception-diff
  program: merge_local.rb
  ruby:    exit 0
  spinel:  exit 1
  exception (ruby):   (none)
  exception (spinel): NoMethodError: undefined method 'merge!' for an instance of Hash

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +0,0 @@
-[["a", 1], [:b, 2]]
```

`update` raises the same way, and so does an Integer-keyed receiver, and an argument that is a parameter, a keyword rest, an instance variable, a constant, a method's value or one of two locals. Written out at the call, `h.merge!({b: 2})`, it is right.

A Hash literal is built as the general Hash when its slot is stored into with keys of more than one class. `widen_mixed_key_hash_slots` gathers those classes for each local, global, class variable and instance variable, and for `merge!` and `update` it read only the arguments that are Hash literals. A Hash held in a local was left to the usage fold (`infer_write_container_usage`), and `fold_container_evidence` widens a local for an Integer key but leaves a Hash of another kind as it is for a Symbol key. The receiver stayed a String-keyed Hash, `emit_hash_call` has no arm that merges a Symbol-keyed Hash into one, and the call was emitted as a missing method.

The pass now counts a Symbol key for an argument that is no literal and whose variant is Symbol-keyed, unless the receiver is the general Hash already. The receiver's literal is then built as it is for `h.merge!({b: 2})`, and the merge is emitted by the arm that call uses.

A call in a method that cannot run is not counted: one that is not reachable and whose name the program writes nowhere, as a call, a Symbol or a String. Reachability is not asked alone, because it is settled before `send(:m)` is rewritten to the call it is, and a method reached only that way would keep its raise.

The receiver can be a local, a global or a class variable. It can also be an instance variable of the main object, or one a subclass's method merges into; those two raised TypeError, "can't store Symbol as a key in a Hash of String keys through a boxed receiver". An instance variable merged into by its own class's method was right already and gets the C it had.

The cured program takes one inference round more (4 for 3), or two where the argument is a constant, an instance variable or a method's value (5 for 3). A program that keeps its C takes the rounds it took, or one less.

Not in this change:

- Only a Symbol-keyed argument is read. A global or a class variable given a Hash of Integer or String keys that is no literal still raises: `$h = {"a" => 1}; m = {1 => 2}; $h.merge!(m)`. A local is right for those on master.
- The other direction is still refused at compile time: `h = {a: 1}; m = {"b" => 2}; h.merge!(m)` and `h = {1 => 1}; m = {"b" => 2}; h.merge!(m)`.
- `h.merge!(**m)` and a boxed argument still raise: `[{b: 2}, {c: 3}].each { |x| h.merge!(x) }`.
- A receiver that is a second name for the Hash (`g = h; g.merge!(m)`) or a copy of a literal (`h = {"a" => 1}.dup`) still raises; both are right when the argument is a literal. A constant (`H = {"a" => 1}; H.merge!(m)`) and a method's value (`h = mk; h.merge!(m)`) still raise, as they do with a literal.

Measured on master 80e28dd2:

- `make cident` reports 6,477 identical, 1 differ (the new test); `make infer-test` passes. The new test passes plain and under `SPINEL_GC_STRESS=1` and `2`, built with gcc and with clang, with and without `--share-strings`; master prints its first 3 lines of 34 and raises at the first `merge!` of a local.

Measured on master 8dc5522, where the change is the same lines:

- A table of 343 programs (7 receivers by 7 arguments by `merge!`, `update`, `merge`, `merge!` with a block, `merge!` with two arguments, `replace` and `h = h.merge(m)`), in the three modes: master is right in 247 and raises in 96. Those 96 are right here; the 247 get the C they had.
- 1,752 generated programs (nine receivers, eight arguments, the reached and the unreached call, seventeen reads and seven later uses, fourteen places the receiver is held): 1,186 get the C they had. The 566 that get other C, in the three modes: 364 that raise on master are right here (344 the NoMethodError, 20 the TypeError); 190 that are right stay right, all with the `merge!` behind a condition that is false in the run (the cost in the first lines); 12 print a wrong line on master and are right here (with the `merge!` not reached, `g = h; g["a"] = 5` stored into a copy). None that was right is wrong, and none that raised prints a wrong line.
- 200 programs for the call in a method (5 receivers, 4 arguments, 10 ways the method is or is not called), in the three modes: 40 whose method nothing names get the C they had; 96 that raise on master are right here (a call, a block, a lambda, `send`, and `public_send` or `method(:m).call` on an object or a class); 40 that were right stay right with other C (the call behind a condition, and a method only named by a Symbol); 12 raise on both (`method(:m).call` at the top level is a missing method on master); 12 call the method by `public_send` at the top level, where it is private: on master 8dc5522 that ran the method, so they raised at the `merge!` and print here; master 80e28dd2 raises NoMethodError for the `public_send` as CRuby does, and there they are right on both.
- The three modes of the table and of the 1,752 were run on master 9274c732; on 8dc5522 every program of the table has the C it had there, with and without this change, and the 8 of the 566 whose C moved were run again.

Test: `test/hash_merge_bang_symbol_keyed_argument.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6; not run under 4.0 here)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: nothing
