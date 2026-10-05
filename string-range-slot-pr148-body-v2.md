<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
$span = ("a".."z")
def fill(i)
  a = "a#{i}"
  z = "z#{i}"
  $span = (a..z)
end
warm = (1..5000).map { |k| "warm-#{k}" }
i = 0
while i < 200
  fill(i)
  junk = (1..3000).map { |k| "j#{k}" }
  r = $span
  puts "#{i}: #{r.first}..#{r.last}" unless r.first == "a#{i}" && r.last == "z#{i}" && junk.size == 3000
  i += 1
end
puts "done"
```

printed `0: j44..j45` and `161: j284..j285` before `done`, in a plain run with gcc and with clang. CRuby prints `done` alone. With `SPINEL_GC_STRESS=1` every one of the 200 turns read another String's bytes, and level 2 stopped at "the mark reached a freed heap string".

A String Range sits in its file-scope slot by value and carries two GC strings. The lines `codegen_program` writes into `sp_mark_user_globals` mark a slot that is a String, a boxed value or a reference, and ask `needs_root` for the last, which says no for a slot that is not itself a reference. Nothing marked the two ends, and the next collection freed them while the slot still named them.

The four loops that write those lines (globals, constants, class-level instance variables, class variables) now share one function, `emit_static_slot_mark`, which marks each end of a String Range as `emit_class_scan` does for an instance variable (#4353). A class or a Struct with a String Range instance variable or member has a class-level slot of that name, so its program gains the two mark lines for it as well. Every other program gets the C it had.

Not changed, and as on master:

- An instance variable or a Struct member holding a String Range takes no write barrier. That is its own commit.
- A constant whose two ends are both made in the assignment, `R1 = ("m" + 1.to_s.."m" + 3.to_s)`, still stops at level 2: the first end is lost before the slot is written. That is the piece this one depends on; with it beneath the constant is right at every setting.
- `inspect` of a String Range does not hold the text of its first end while it makes the second. At level 2, where master stopped before the read, a global that now keeps its ends reaches that fault and prints the wrong line the same Range prints from an Array element on master (see below). #<fork PR 51> cures it: with both, each such program is right at every setting.

Measured on master c6bbdfbc9, against CRuby 3.3.6, with gcc 13.3 and clang 18.1, in a plain run, under `SPINEL_GC_STRESS=1` and `2`, and with `SPINEL_GC_MINOR=1 SPINEL_GC_VERIFY_GEN=1` without and with level 1:

- 172 generated programs: a Range stored into a global (in a method and in the loop), a class variable or a class-level instance variable, four String and four other kinds of Range, thirteen reads. Right at all five settings: 36 on master, 160 here, the same with both compilers. Of 860 runs a compiler: 548 right on both, 268 not right on master and right here, 20 the same and not right. Right on master and not right here: 0.
- 8 programs, all of them `inspect` of a String Range, abort on master at level 2 and print a wrong line here with exit 0, and at level 1 print another wrong line than master's. Each line is byte for byte what master prints at that setting for the same `inspect` on an Array element: the Range is whole, `sp_srange_inspect` loses its own temporary.
- The other 4 not right are `(i..i + 2.5)` read with `last`, which raises NotImplementedError by name on master and here.
- `make cident REF=c6bbdfbc9`: 6054 identical, 3 differ, 0 refusal changes. The three are `range_dup_unfrozen`, `str_range_endpoints_root` and the new test, by the mark lines of their String Range slots. A class with a String Range instance variable has a class-level slot of that name too, so it gains two lines: of the 1,634 programs measured for the instance variable's own commit, the 924 with such a slot change by those two lines and nothing else.
- Cost (callgrind): two `sp_mark_string` calls a slot a mark. 300,000 stores into a global beside a constant, 166,367,600 to 166,469,971 (+0.06%). optcarrot's C is unchanged.
- `make gc-stress-test` passes; without the change the new test aborts there. `tools/refusals.sh` passes. `make scale-test` gives master's four numbers (1.71x, 4.73x, 6.08x, 4.22x).

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (equal under CRuby 4.0.7)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: #<fork PR 94> (a constant whose two ends are both made in the assignment loses the first before the slot is written)
