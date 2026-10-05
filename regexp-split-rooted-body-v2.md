<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`split` and `rpartition` with a Regexp crash in a plain run on a large String:

```ruby
s = ("abcdefghij" * 40 + " ") * 2000
n = 0
8.times { a = s.split(/ /); n += a.size }
p n          # exits 139; CRuby prints 16000
```

The same loop over `s.rpartition(/ /)` exits 139 too, and on a 6 KB String 20,000 rounds of
`rpartition(/b/)` answer a freed head or match 113 times. With a String separator both are
right.

`sp_re_split_limit` kept the Array it fills in a C local with no root, so the collection that a
later piece's allocation starts freed the Array. `sp_re_rpartition` rooted its Array but made
the head, the match and the tail before it pushed any of them, so the head and the match had no
holder while the next piece was allocated. Now split roots its Array where it is made, as
`sp_re_scan` does, and rpartition pushes each piece as it is made, as `sp_str_partition` does.

Measured on master 2bd029b7e with gcc 13.3 and clang 18.1, the runtime built with each; the
test, the programs above and the cost were run again on 23e9734df:

- `test/regexp_split_rpartition_rooted.rb` exits 139 on master in a plain run, prints a wrong
  line under `SPINEL_GC_STRESS=1` and aborts under 2. With the change it is right at all three.
  It is in `GC_STRESS_TESTS`, and `make gc-stress-test` passes.
- The change is in lib/sp_re.c: the generated C does not change.
- The 15 corpus programs whose C calls one of the two functions are right on both in a plain run
  and at level 1. At level 2, 14 of them abort on master and 13 of those are right with the
  change. test/string_nul_regexp.rb stops on both, in another statement: master aborts after 8
  lines, at its split; with the change it prints 30 right lines of 32 and stops at
  `s.match(/a(?<p>.)b/m).named_captures` with a fault on the GC mark path (exit 139).
- A set of 2,194 programs, one case each, built and run on both: split with no limit and with
  -1, 1, 2, 3 and 50, rpartition, and partition as a control; eleven receivers from empty to
  800 KB, multi-byte, binary and with NUL bytes; thirteen patterns with captures, empty matches
  and no match; at the top level, in a loop, in a method, in a thread, with the Regexp in a
  local, a boxed receiver and an instance variable.
  - Plain run: 188 fail on master with gcc (126 crash, 4 raise, 58 answer wrong; 186 with
    clang) and are right with the change. No program that is right on master changes.
  - Level 1: 365 answer wrong on master with gcc (368 with clang) and are right with the change.
  - Level 2: 1,350 abort on master and are right with the change. 258 abort on both, every one a
    `partition(/re/)`, below.
  - Level 2, an abort that becomes a wrong line, of two kinds. Seven programs of the set abort
    on master and answer wrong with the change, and each prints byte for byte what master prints
    for it in a plain run: they are seven of the nine that are wrong on both, last below, where
    master's abort came first. The other kind is a line master gets right in a plain run:
    `s = ("w" + 1.to_s + " b c d ") * 5; t = []; for x in s.split(/\s/) do t << x + "!" end; p t.size`
    prints 20 on both at every other setting; at level 2 master aborts and the change prints 10.
    The same loop over `s.split(" ")` prints the same 10 on master at level 2: the for loop walks
    an Array held in no root, and that fault is reached where master's split aborted first.
- Cost (callgrind, 200,000 calls): `"ab cd ef".split(/ /)` goes from 1,333 to 1,353
  instructions a call and a subject with no match from 594 to 618; `rpartition(/ /)` goes from
  1,183 to 1,182.

Left alone:

- `partition(/re/)` builds its Array in the emitted C and holds it in no root while the
  pre-match String is made: `puts "hello world".partition(/o/).inspect` aborts under
  `SPINEL_GC_STRESS=2`, as on master. Nothing was seen in a plain run.
- A split into very many pieces is slow under a stress level, as `chars` is. 802,000 pieces
  take 35 s at level 1 (`s.chars` on master: 33 s) and 80,200 take 37 s at level 2 (`s.chars`
  on master: 37 s). On master such a split was quick only because its Array was never marked.
  28 programs of the set pass a 30 s limit for that reason; with a 25-minute limit all 28 are
  right at level 1.
- Nine programs of the set answer wrong on both: a binary String against a multi-byte Regexp
  answers where CRuby raises Encoding::CompatibilityError (7), and `"a\0b".split(/a/)` drops a
  last piece that begins with a NUL byte (2).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
