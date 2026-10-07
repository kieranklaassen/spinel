<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An exception made through its class's own `initialize` can answer another String's bytes for its message. The cure costs a right program 16 instructions an exception made through such an `initialize` (4,555 to 4,571 for `super(msg)`; callgrind, gcc; 21 more with clang), and `KeyError.new` with both keywords 29 (777 to 806). `super("fixed")`, a class with no `initialize` and a raise of a builtin exception emit the C they did and run the same count.

```ruby
class ParseError < StandardError
  def initialize(line, what) = super("line #{line}: #{what}")
end
errs = []
300000.times { |i| errs << ParseError.new(i, "unexpected token") }
bad = 0
errs.each_with_index do |e, i|
  bad += 1 if e.message != "line #{i}: unexpected token"
end
p bad
```

master prints `1` in a plain run, with gcc and with clang; CRuby prints `0`. One exception answers another String's bytes for its message; at `SPINEL_GC_STRESS=2` the mark stops at a freed heap string. `spinel diff` on master:

```
spinel diff: output-diff
  program: lead.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-0
+1
```

With this commit `spinel diff` says `same`.

At `SPINEL_GC_STRESS=2` the freed bytes are printed and the program exits 0:

```ruby
class Aa < StandardError
  def initialize(m = "aa", z = "az" * 2) = super(m + z)
end
begin
  raise Aa
rescue Aa => e
  p e.message
end
```

master prints `"\xDB\xDB\xDB\xDB\xDB\xDB"` there; with this commit it prints `"aaazaz"`.

`emit_super` writes the message handed to `super` in an exception's `initialize` as `self->msg = <value>`, and `emit_new_call_arms` writes the key and the receiver given to `KeyError.new`, `NameError.new` or `FrozenError.new` into the exception it has just made. Making the value can collect, and the collection promotes the rooted exception, so the store puts a young value into an old holder and nothing records it: the next minor collection frees the value while the exception holds it. The barrier pass finds a store by `->iv_`; these fields are `msg`, `xkey` and `xrecv`.

Each of these stores is now followed by `sp_gc_wb`, after the store as in `sp_exc_new_sub_sized`. A bare `super` takes it too, because its parameter may have been assigned in the method (`msg = msg + "!"`, then `super`: 3 messages of 400,000 are wrong on master). The key and the receiver take one each, because making the receiver can collect a second time. A literal message takes none, by the pass's own test for a value that is never young.

33 programs of the corpus change, each line by the barrier call alone; optcarrot's generated C is byte-identical.

Not here: a class that defines its own `message` still prints an empty line for `to_s`, where CRuby prints the class name.

Test: `test/exception_keeps_value_made_after_it.rb`, added to `GC_STRESS_TESTS`; on master each of its five loops stops the mark. Six tests already in the tree stop there on master too and pass with this commit: `exception_super_message`, `exception_super_interpolated_message`, `exception_reopen_initialize`, `raise_block_initialize`, `raise_class_value_user_initialize`, `string_handle_initialize`. `default_reads_callee_self` no longer stops there and now prints two lines of freed bytes for `self.class.name`, at `SPINEL_GC_STRESS=2` only and never in a plain run; master prints the same for `def kind = self.class.name` in an exception class with no `super` in it.

Also run: 860 generated programs (how the class gets its message, its parent, how the exception is made and kept, `message` and `to_s`, the fields of KeyError and NameError) with gcc, with clang and with `--share-strings`, `SPINEL_GC_STRESS` unset, 1 and 2. 475 print CRuby's answer in all nine runs on master and 835 with this commit; the other 25 are the `to_s` line above. None that is right on master is wrong with this commit.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
