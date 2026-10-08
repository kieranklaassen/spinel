<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`begin ... end while t` runs its body once before it tests `t`, but the nil fact took the loop's condition for a guard of that body. A call there on a String local that is nil got no nil test: an append did nothing and the method answered nil, and `t.size` read through NULL, where CRuby raises NoMethodError. The cost is the nil test such a call now carries on every turn: 2 instructions a turn by callgrind, in a loop whose local may be nil when it starts. `while t` keeps its guard and its C.

```ruby
def f(c)
  t = +""
  t << "4"
  t << "2"
  t = nil if c
  i = 0
  begin
    t << "a"
    i += 1
  end while t && i < 2
  t
end
p f(true)    # master: nil. CRuby: NoMethodError
```

`nf_local_guarded` (`src/analyze_nil.c`) takes a while loop's condition for a guard of the loop's body, which is right for `while t`: the test runs first. A loop with Prism's begin-modifier flag runs its body once before any test, so on that turn `t` is whatever reached the loop. The arm now leaves such a loop out, and a call in its body is planned as it is ahead of the loop.

Cost, by callgrind on master 9c7ea3ce, before and after: 5,000,000 turns of `begin; i += t.size; end while t && i < n` take 1,475,793,175 and 1,485,792,047 instructions with gcc, 1,456,125,130 and 1,466,126,258 with clang, the same with `--share-strings`. The loop that tests first and an Integer local in a loop that tests after (it was tested already) compile to the same C. `tools/cident.sh` on that master: 6,512 identical, 1 differ (this test), 0 refusal changes, 0 refused by both, of 6,513.

Of 26 String calls tried in such a body on a nil local, 21 were silent or crashed and now raise NoMethodError; `+`, `*` and `force_encoding` raised already. Not in this change, each the same on master: `x = +t` there answers nil in the default build, and `t.to_i` crashes where CRuby answers 0.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this head on linux-x86_64 before opening: the new test with gcc and clang, with and without `--share-strings`, plain and under both GC stress modes; `ruby tools/gate.rb check`; `tools/cident.sh` against master 9c7ea3ce; `make nil-check-test`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (the tests have none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: nothing
