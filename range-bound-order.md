<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
$log = []
def lg(x) = ($log << x; x)
n = 3
p (n..(n = 5))                    # 3..5 in Ruby, 5..5 here
p (lg(1)..lg(2)), $log            # logs 1 then 2 in Ruby, 2 then 1 here
```

Before: with gcc a Range's last bound ran before its first. Two bounds with an effect ran in reverse, and a first bound read what the last had already changed: a local the last bound assigns, an instance or a global variable a call in it writes, a local a proc it calls assigns. Integer, Float and String Ranges alike, whatever reads the Range (`to_a`, `size`, `each`, `map`, `step`, `include?`, a `when`, `clamp`). clang ran these in source order.

After: the first bound runs first, with either compiler.

How: `emit_range_expr` writes the two bounds as arguments of one C call (`sp_range_new`, `sp_frange_new`, `sp_srange_new`), whose order C leaves open; gcc runs the last one first and clang the first. Where the order shows (`args_order_matters`: two bounds with an effect, or a first bound reading what the last can change) the first bound now runs into a temp at the Range, ahead of the last, and the temp is rooted when its type is one the collector follows. Any other Range is emitted as before. One file, `src/codegen_expr.c`, 22 lines; `emit_range_expr` goes from 165 lines to 187.

`test/range_bounds_run_in_order.rb` prints 68 lines. On master built with gcc 30 of them are wrong; with this change it prints its `.expected` at `-O0` to `-O3`, with clang, and under `SPINEL_GC_STRESS=1` and `2`.

The rooted temp also closes a fault that is not about order. Two String bounds that both allocate left the one C built first unrooted while the other was built:

```ruby
k = 3
n = 0
(("a" * k)..("a" * (k - 1) + "c")).each { |x| n += x.size }
p n                               # 9
```

On master this prints 9 in a plain run and under `SPINEL_GC_STRESS=1`; under `SPINEL_GC_STRESS=2` the gcc build stops in the collector's check and the clang build prints 0. Here it prints 9 with gcc and with clang at levels 0, 1 and 2. The new test has no such line; this program is not in the gate.

Generated C against master (`make cident REF=origin/master`): CIDENT_LINE. Besides the new test three tests differ (`cell_value_struct_time_capture`, `main_body_split`, `own_def_overrides_module_reader`), each by a first bound in a temp, and each still prints its `.expected`. optcarrot's generated C is byte-identical.

Cost under callgrind: an Integer or Float first bound in a temp costs nothing (a million `(lg(i)..lg(i + 3)).size` take the same instructions before and after, to within 30 of 17 million); a String first bound costs its root, four instructions a Range.

Left alone, wrong on master and unchanged:

- A Range literal handed straight to a slice: `a[lg(1)..lg(3)]`, `s[lg(1)..lg(3)]` and `a.slice(lg(1)..lg(3))` still run the last bound first with gcc.
- `for i in lg(1)..lg(3)` runs the last bound first with either compiler.
- A first bound that assigns or writes what the last reads, when the last is not a call: `((n = 1)..n + 2)`, `(bump..$g + 2)` where `bump` writes `$g`. Wrong with gcc. With a call in the last bound it is right now.
- A bound whose only effect is a raise that is not a call: `((10 / z)..lg(2))` with `z` zero still logs 2 with gcc.
- A first bound that is a method that only raises: `(boom(1)..lg(2))` still logs 2 with gcc.
- `(s..(s << "b"))` with a String local is right with gcc and wrong with clang, as on master.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: # (nothing)
