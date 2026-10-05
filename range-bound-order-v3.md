<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
$log = []
def lg(x) = ($log << x; x)
n = 3
p (n..(n = 5))                    # 3..5 in Ruby, 5..5 here
p (lg(1)..lg(2)), $log            # logs 1 then 2 in Ruby, 2 then 1 here
```

Before: with gcc a Range's last bound ran before its first. Two bounds with an effect ran in reverse, and a first bound read what the last had already changed: a local the last bound assigns, an instance or a global variable a call in it writes, a local a proc it calls assigns. Integer and Float Ranges, and a String Range whose first bound is a read (`(s..(s = "c"))`), whatever reads the Range (`to_a`, `size`, `each`, `map`, `step`, `include?`, a `when`, `clamp`). clang ran these in source order.

After: the first bound runs first, with either compiler.

How: `emit_range_expr` writes the two bounds as arguments of one C call (`sp_range_new`, `sp_frange_new`, `sp_srange_new`), whose order C leaves open; gcc runs the last one first and clang the first. Where the order shows (`args_order_matters`: two bounds with an effect, or a first bound reading what the last can change) the first bound now runs into a temp at the Range, ahead of the last, and the temp is rooted when its type is one the collector follows. Any other Range is emitted as before. One file, `src/codegen_expr.c`, 22 lines.

This stands on the pull request "A String Range made on the spot keeps its ends, made in order, until it is read". That one puts the first end of a String Range in a rooted temp when both ends are made on the spot, so that neither is collected. This one asks whether the order shows, of a Range of any kind; that arm leaves alone a first bound this one has already put in a temp (`arg_ran_first`).

`test/range_bounds_run_in_order.rb` prints 68 lines. Built with gcc, 29 of them are wrong on master and 28 on the pull request this stands on; with this change it prints its `.expected` with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`.

Generated C against the pull request this stands on (`make cident REF=` its commit): 6078 identical, 5 differ, 0 refusal changes. `main_body_split` and `own_def_overrides_module_reader` gain a first bound in a temp. `cell_value_struct_time_capture` and `string_range_fresh_ends` had a String first bound in a temp already; it is now this change's temp, the same root spelled `SP_GC_ROOT_STR`. The fifth is the new test. Each of the four prints what it printed, with gcc and clang at the three levels. optcarrot's generated C is byte-identical.

740 small programs written around a Range's two bounds, gcc and clang, plain and under `SPINEL_GC_STRESS=1` and `2`, against the pull request this stands on: none loses a cell. Right in all six: 231 before, 444 now. With clang 454 are right at the three levels before and after.

Cost under callgrind: none. A million `(lg(i)..lg(i + 3)).size` take 17,345,547 instructions before and after; 100,000 `(mk("a")..mk("c")).first.size` take 60,342,768 before and after.

Left alone, wrong on master and unchanged:

- A Range literal handed straight to a slice: `a[lg(1)..lg(3)]`, `s[lg(1)..lg(3)]` and `a.slice(lg(1)..lg(3))` still run the last bound first with gcc.
- `for i in lg(1)..lg(3)` runs the last bound first with either compiler.
- A first bound that assigns or writes what the last reads, when the last is not a call: `((n = 1)..n + 2)`, `(bump..$g + 2)` where `bump` writes `$g`. Wrong with gcc. With a call in the last bound it is right now.
- A bound whose only effect is a raise that is not a call: `((10 / z)..lg(2))` with `z` zero still logs 2 with gcc.
- A first bound that is a method that only raises: `(boom(1)..lg(2))` still logs 2 with gcc.
- `(s..(s << "b"))` with a String local is right with gcc and wrong with clang, as on master.
- A first bound that is a second name for a String the last bound changes in place, `(idn(s)..(s << "x"; "zz".dup))`, shows the String as it was. That is the stated cost of the pull request this stands on, and this change leaves those programs as they are there.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: the pull request "A String Range made on the spot keeps its ends, made in order, until it is read" (it keeps a String Range's two ends alive; without it `(a.to_s..b.to_s).cover?(sa.succ)` in a loop of 120, right on master, counts 105 where it should count 0 under `SPINEL_GC_STRESS=2`)
