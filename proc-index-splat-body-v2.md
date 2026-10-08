<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`pr[*list]` raised ArgumentError for a Proc when the list held more than two values.

```ruby
pr = proc { |*x| x }
l = [1, 2, 3].dup
p pr[*l]
```

```
spinel diff: exception-diff
  ruby:    exit 0
  spinel:  exit 1
  exception (ruby):   (none)
  exception (spinel): ArgumentError: wrong number of arguments (given 3, expected 1..2)
```

**It has a cost, yours to weigh.** A program that was right because its lists held one or two values now compiles its raise arm as a call. Compiling such a site costs 5.1 M instructions more (200 of them: 3,272,248,987 on master, 4,285,808,849 here). Running one costs 2 to 3 instructions a call with gcc (117.3 to 119.3 for a list of one value, 163.3 to 166.3 for two) and 0 to 2 with clang. An Array, a String or a Hash receiver compiles to the C it had.

`pr[*list]` is `pr.call(*list)`, and a Proc takes whatever the list holds. With a list whose length is known only at run time the call was built as Array#[] is: an arm a length, and a raise past two. The arms are built before the receiver has a type, so `splat_dispatch_on_length` only marks its raise arm, and `desugar_index_splat_callable`, run in the fixpoint once the types have settled, makes that arm `recv.call(*list)` where the receiver is a Proc or a Method. The raise is kept as a node off the tree and put back if the receiver's type moves on.

It is made only for the receivers whose `call(*list)` is right today: a Method of a def of the program, and a Proc in a program whose Procs are all blocks, lambdas or such Methods.

Checked on master 548d4196def8:

- `test/proc_index_splat_any_count.rb` raises at its fifth line on master and passes here under `SPINEL_GC_STRESS=0`, `1` and `2`, with and without `SPINEL_GC_VERIFY=1`, with gcc and clang.
- 56 kinds of callable, each called by `call` and by `[]` with lists of 0 to 4 values (280 rows), each against CRuby: 12 go from the raise to right, none that was right is lost, and no wrong answer becomes another.
- 1,085 generated forms (31 receivers, 5 sources of the list, lengths 0 to 4): 700 compile to the same C; of the 385 that change, 231 go from the raise to right and 154 were right and stay right.
- `tools/cident.sh` against 548d4196def8: 6484 identical, 0 differ, 0 refusal changes.
- Compile cost where no Proc is indexed: `kernel_conv_protocol` 739,142,698 instructions on master and 739,388,158 here; `bundle_misc_b` 428,109,441 and 428,188,535.

Left alone, each raising as before:

- A program that curries, takes a builtin's or an accessor's Method (`5.method(:+)`, an `attr_reader`'s), or makes a Proc from a Symbol, a Hash or another object. `call(*list)` answers wrongly for some of those today (a curried lambda answers a Proc past its count; an accessor's Method answers its value whatever the count), and the ArgumentError is better than that answer.
- A boxed receiver: the test of what it holds would bring the class helpers into every such program.
- A splat beside other arguments (`pr[1, *list]`), and a class's own `[]`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
