<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A value object among a `yield`'s arguments, or as a keyword argument's value, was rooted as if it were a pointer: the program died in the collector, or the object's String was freed under it.

```ruby
class Zero
  def initialize(q) = @q = q
  def q = @q
end

class Name
  def initialize(r) = @s = "hello world " * r
  def len(k) = @s.length + k.length
end

def two_names
  yield Name.new(240), "ab" + "cd"
end

z = Zero.new(1)
bad = 0
2000.times { two_names { |n, k| bad += 1 unless n.len(k) == 2884 } }
p bad
p z.q
```

Master (06064727f) dies with a segmentation fault and prints nothing. CRuby prints `0` and `1`. Without `Zero`, so that `Name` is the program's first class, master prints `8`: eight of the 2,000 Strings were freed while the block read them.

When a later argument may allocate, `emit_arg_temp` runs each argument into a temp and roots it on `needs_root` alone. A value object lives in the temp itself, so the C was `sp_Name  _t5 = sp_Name_new(240LL); SP_GC_ROOT(_t5);`, which hands the collector the struct's first word, the class id, as a pointer: NULL for the first class, so nothing is held; a fault in the mark for any later one. The temp now roots the object's String fields, as a local of the kind does (`emit_gc_root_tmp_refs`), and takes no root when it has none. `takes(n: Name.new(240), k: "ab" + "cd")` goes through the same temp and is cured with it.

`make cident` against master: the new test alone differs (6334 identical). A value object reaches an argument temp only at a `yield` and as a keyword value, and no program of the corpus has one. 200,000 such yields under callgrind: 167,303,362 instructions before, 167,303,349 after; with a class of two Integers, which no longer takes a root, 90,247,277 before and 85,446,952 after.

Test: `test/value_object_yield_argument_root.rb`, 9 lines; master dies on it with a segmentation fault.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
