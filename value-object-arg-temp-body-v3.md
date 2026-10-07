<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`test/poly_recv_default_value_type.rb` dies on master with a segmentation fault under `SPINEL_GC_STRESS=2`: a value object held in an argument temp is rooted as if it were a pointer. At a `yield` or as a keyword value the same root kills a plain run, or frees the object's String under it.

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

Master (26d456ec1) dies with a segmentation fault and prints nothing. CRuby prints `0` and `1`. Without `Zero`, so that `Name` is the program's first class, master prints `8`: eight of the 2,000 Strings were freed while the block read them.

Four places run a call's arguments into temps when a later one may allocate, and each rooted its temp on `needs_root` alone: `emit_arg_temp`, `emit_rooted_operand`, `emit_dispatch`'s own temp for a keyword value, and the local `emit_args_filled_argv` hoists an argument into when a default reads an earlier parameter. A value object lives in the temp itself, so the C was `sp_Name  _t5 = sp_Name_new(240LL); SP_GC_ROOT(_t5);`, which hands the collector the struct's first word, the class id, as a pointer: NULL for the first class, so nothing is held; a fault in the mark for any later one. Each place now roots the object's String fields, as a local of the kind does (`emit_gc_root_tmp_refs`), and takes no root when it has none. The keyword forms are `take(n: Name.new(240), k: "ab" + "cd")`, `take(k: "k#{i}", n: Name.new(240))` and a callee `def take(n:, k: "abcd", j: k.length)`.

This stands above "A value object under construction roots the Strings initialize has written". A class with two Strings loses the first inside its constructor, and with this change alone such a program would go from master's fault to a wrong answer.

`make cident` against that pull request's commit: 6342 identical. Besides the new test one program changes, `test/poly_recv_default_value_type.rb`, whose `def join(part, sep = self)` puts the by-value receiver in such a temp. A value object reaches an argument temp at a `yield`, as a keyword value and as a default that reads `self`. 200,000 rounds of `yield Name.new(2), "ab" + "cd"` under callgrind: 167,303,362 instructions before, 167,303,349 after; with a class of two Integers, which no longer takes a root, 90,247,277 before and 85,446,952 after. With `Name.new(240)`, where the sum was wrong before, 2,093,865,698 and 2,099,791,804 (+0.3%): the collector now marks the String it used to drop.

Test: `test/value_object_yield_argument_root.rb`, 14 lines; master dies on it with a segmentation fault. It and `test/poly_recv_default_value_type.rb` join `GC_STRESS_TESTS`: a class with no String took the root too and faults only there.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [x] Depends on: the pull request "A value object under construction roots the Strings initialize has written"
