<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A `for` loop over the Array a call answers lost the Array while it walked it:

```ruby
def words(n) = (1..n).map { |i| "w" + i.to_s }
out = []
for w in words(3000)
  out << w.upcase + "?" * 20
end
p out.size    # 3000 in Ruby; on master: undefined method 'upcase' for nil (NoMethodError)
```

The loop takes the Array into a C temp, and nothing else holds it:

```c
{ sp_StrArray *_t9 = sp_words(3000LL);
  for (sp_int _t10 = 0; _t10 < sp_StrArray_length(_t9); _t10++) {
```

The first collection the body causes takes the Array. `for l in text.lines`, `for w in a + b` and `for k, v in pairs(n)` fail the same way, with a NoMethodError or a crash. So does a variable's Array once the body gives the variable another:

```ruby
def rebound(n)
  ws = mk(n)          # [0, 3, 6, ...]
  sum = 0
  for w in ws
    ws = mk(2)
    sum += w
  end
  sum
end
p rebound(3000)       # 13495500 in Ruby; 1546860 on master
```

The Array walk of `emit_for` now roots its temp, as the String Range, boxed value and Hash walks beside it already do.

One decision: the root is left out where something else holds the Array for the whole loop, which is a constant, or a variable the body cannot rebind (`read_rebound_by`). Rooting every loop was tried first; on `for x in a` over a local, which was right, it cost 7 instructions a loop entry over Integers and 15 over Strings. As it is, that loop compiles to master's C. A loop over a call's answer that was right pays the root, 8 instructions an entry (callgrind, 200,000 entries of `for x in b.a` through a reader: 14,863,506 to 16,463,513).

On dafa0d047 the generated C of 16 of the 6,280 programs under `test/`, `benchmark/` and the packages changes, each by such a root.

`test/for_call_array_root.rb` walks a method's answer, `String#lines`, the sum of two Arrays, pairs into two loop variables, an instance variable the body clears and a local the body rebinds. On master (dafa0d047, gcc and clang) it raises NoMethodError in a plain run, so it is an ordinary test and not in `GC_STRESS_TESTS`.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on dafa0d047)
- [ ] Depends on: # (nothing)
