<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
g = { a: +"q", b: +"q", c: +"q", d: +"q", e: +"q" }
pad = (1..40).map { |i| "pad" + i.to_s }
m = g[:a]
m.concat((m << ("z" * 300); "w"))
p g[:a].size                      # 302 in Ruby; a segfault here, with gcc and with clang
```

A String read out of a Hash or a mixed Array sits behind a shared handle. When `concat` or `prepend` is called on it and an argument grows it, the call joins freed bytes. With one key in the Hash the same program prints 302 in a plain run and stops under `SPINEL_GC_STRESS=1` and `2` ("fault on the GC mark path"); `u.concat("n", big(u, 500))`, where `big` appends 500 bytes to its argument, prints size 503 built with gcc and size 3 built with clang.

After: the receiver's text is read after the arguments have run, where CRuby reads it, and all of these print what CRuby prints, with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`.

How: the boxed dispatch's String arm (`emit_face_arm`, `src/codegen_call_recv.c`) reads the handle's bytes into a rooted temp in the statement's prelude and then re-enters the call, which renders the arguments. `concat` and `prepend` join that temp with their arguments afterwards, so an argument that grows the receiver moves the bytes and the temp names the old ones. Where an argument of `concat` or `prepend` can change a String (it may run code of the program, `subtree_may_run_proc`, or calls a String mutator by name, `an_str_mutator_name`), the arguments now run first, each into a rooted temp (`emit_args_in_source_order`), and the text is read after them. With no such argument (a literal, a variable, `j.to_s`) the call's C is master's. `<<`, `+` and `insert` go through runtime helpers that read the handle themselves and were right.

The arguments that are moved ahead run in source order there. The order in which several arguments of `concat` and `prepend` run in general is another pull request's; this one changes only where the receiver is read.

`test/boxed_string_concat_reads_after_arguments.rb` prints 27 lines: one growing argument, a method that grows its argument, a lambda, the element read as the receiver, several arguments, the call's value, `prepend`, a parameter that takes a String on one call and an Integer on another, sixty rounds. On master it ends in a segfault before its first line, with gcc and with clang, plain and under stress; here it prints its `.expected` in all six, and with `--int-overflow=promote`.

Generated C against master (`make cident REF=9c4eec71e`): 6133 identical, 3 differ, 0 refusal changes. The three are the new test and `packages/optparse/test/optparse_parse_default_argv.rb` and `optparse_parse_forms.rb`: `rest.concat(argv[(i + 1)..])` on a boxed `rest`, whose argument now has a temp of its own. Both print what they print on master in all six cells (`optparse_parse_default_argv` stops at `SPINEL_GC_STRESS=2` on master and here alike). optcarrot's generated C is byte-identical.

A matrix of 1,152 programs, measured on c2dadf497: `concat` and `prepend`; eight receivers; eight argument lists in which one argument or several grow the receiver by 40, 300 or 5,000 bytes; as a statement, a value and an argument; each built with gcc and with clang and run plain and under `SPINEL_GC_STRESS=1` and `2`.

- 720 on a boxed receiver (a local read from a Hash or a mixed Array, the element itself, a parameter that takes such a String on one call and an Integer on another): master prints CRuby's answer in all six for 27, crashes in a plain run for 231, prints a wrong line in a plain run for 150 and faults only under stress for 312. Here all 720 print CRuby's answer in all six.
- 432 on a String that is not boxed: master's C byte for byte, and its result (see below).

Cost, in instructions counted by callgrind over 200,000 calls on a boxed receiver (measured on 4d56c1573):

```ruby
def str(j) = j.to_s
n = 0
2000.times do
  h = { a: +"" }
  u = h[:a]
  j = 0
  while j < 100
    u.concat(str(j))              # also measured: u.concat(j.to_s) and u.concat("ab", "c")
    j += 1
  end
  n += u.size
end
p n
```

`u.concat(j.to_s)` and `u.concat("ab", "c")` have master's C. `u.concat(str(j))` goes from 110,666,181 to 113,863,606 instructions, 16 a call: the argument's rooted temp.

Not here, wrong on master and not made right:

- A String that is not boxed. Of the 432 programs above, 189 are wrong on master and here alike: `s.prepend(big(s, 300))` on a String with a second name segfaults with gcc under `SPINEL_GC_STRESS=1`, and `s.concat("n", big(s, 300))` on a String a lambda captures appends the "n" ahead of the growth. Another site.
- An argument that assigns the receiver's variable: after `u.concat((u = g[:b]; "w"))` `u` still names the first String.
- `y.concat("n", 119)`, an Integer argument, on a boxed receiver: right in a plain run, stops under `SPINEL_GC_STRESS=2`.
- A String that reached a parameter as a plain value, where another call passes an Integer: `def run(x) = x.concat((x << ("z" * 300); "w"))` changes a copy, and the caller's String keeps size 1. In an older matrix of 1,158 programs without the growth (also c2dadf497; none loses a cell, 603 right in all six on master and 747 here) 30 programs of this kind print a wrong line in a plain run on master and stop under `SPINEL_GC_STRESS=2` on the freed bytes; here they print a wrong line master prints, at every level.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (run under 3.3.6 only)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: # (nothing)
