<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`KeyError.new` can answer its message for its key. Stated cost (callgrind, instructions an exception made, with gcc and then with clang): 11 and 14 for each key or receiver that is recorded. `KeyError.new("missing", key: "k#{i}")` goes from 962 to 973 and from 952 to 966, and with `receiver: [i]` as well from 1,265 to 1,286 and from 1,263 to 1,292. A key or receiver read from a variable is recorded too (963.4 to 980.4 and 956.0 to 971.0) though master ran that one right: an exemption there would rest on the constructor's last line and on the key's making, not on the value alone. A key or receiver that is nil, true or false, an Integer, a Float, a Symbol or a frozen String literal emits the C it did and runs the same count.

```ruby
errs = []
300000.times { |i| errs << KeyError.new("missing", key: "k#{i}") }
bad = 0
errs.each_with_index { |e, i| bad += 1 if e.key != "k#{i}" }
p bad
```

master prints `1` in a plain run, with gcc, with clang and with `--share-strings`; CRuby prints `0`. One exception answers `"missing"`, its message, for its key; at `SPINEL_GC_STRESS=2` the mark reaches a freed heap string. `spinel diff` on master:

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

`emit_new_call_arms` writes the key and the receiver given to `KeyError.new`, `NameError.new` or `FrozenError.new` into the exception it has just made. Making the value can collect, and the collection promotes the rooted exception, so the store puts a young value into an old holder and nothing records it: the next minor collection frees the value while the exception holds it.

Each of the two stores is now followed by `sp_gc_wb`, as the message's store in `emit_super` is. The key and the receiver take one each, because making the receiver can collect a second time. A value that is never a young object takes none: a scalar's box is no object, and a frozen String literal is static storage.

2 programs of the corpus change, each by one barrier call (`test/exception_introspection_accessors.rb`, `test/issue_3030.rb`); optcarrot's generated C is byte-identical.

Not here: an attribute of an exception class that has no `initialize` of its own (`e.ctx = "k" + i.to_s`) still loses its value, 693 of 1,500 in a plain run on master and here; that is the pull request "An attribute of an exception class with no initialize is nil until set, and is marked once set".

Test: `test/exception_keeps_key_made_after_it.rb`, added to `GC_STRESS_TESTS`; on master its FrozenError loop is wrong at `SPINEL_GC_STRESS=1` and the mark reaches a freed slot at 2.

Also run: 234 generated programs (the three classes; the key an interpolated String, a concatenation, a Symbol, an Integer, a literal, an Array or none; the receiver a String, a large String, an Array, a Hash, an object, nil, an Integer, a literal or none; made by `new`, raised and rescued, or made in a method) with gcc, with clang and with `--share-strings`, `SPINEL_GC_STRESS` unset, 1 and 2. 120 print CRuby's answer in all nine runs on master and 234 with this commit.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
