<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A fix with a cost: an append of a boxed String as a statement now tests its tag first, 6 instructions an append with gcc and 3 with clang (callgrind, 200,000 appends). The C of a typed argument is unchanged.

```ruby
def emit(out, x) = out << x
out = "".dup
emit(out, "id=")
emit(out, 55)
emit(out, 10)
p out
```

```
spinel diff: output-diff
  program: append.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-"id=7\n"
+"id=5510"
```

The call with `"id="` boxes `x` for every caller, and the boxed 55 was appended as its digits. `@buf << x` in a method that is handed a String and 0x263A appended `"9786"`. With and without `--share-strings`.

`emit_str_append_arg` holds the rule since "A boxed Integer appended to a String is still a codepoint": a typed Integer is a codepoint, and a boxed value asks its tag at run time. Two statement emitters kept a copy with the typed half only: the `<<` chain and `concat` on a String that is reassigned (a local, an instance variable, a global, a parameter), in `str_mutate_append_bang_arms` and `str_mutate_reassign_arms`. Both now call the helper, as the value position does. A boxed Integer there is its codepoint, one byte on a binary String, and a RangeError out of range.

Not here: a boxed value that is neither a String nor an Integer (a Symbol, an object with `to_str`) is still appended as its text. That is the helper's other side, the same in the value position, and its own pull request above this one.

Test: `test/string_append_boxed_integer_statement.rb` (18 of its 25 lines are wrong on master). The generated C of 20 corpus programs changes: four tests and sixteen of `packages/openssl`, whose Digest appends a boxed argument to `@buf`. All pass.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
