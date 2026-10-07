<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def span(i)
  a = "a#{i}"
  z = "z#{i}"
  (a..z)
end
def junk(i)
  (1..200).map { |k| "j#{k}" }.size
end
$r = ("a".."z")
bad = 0
i = 0
while i < 2000
  $r = span(i)
  junk(i)
  bad += 1 unless $r.first == "a#{i}"
  i += 1
end
puts "global: #{bad}"
```

prints `global: 22` in a plain run, with gcc and with clang (`spinel diff`: output-diff). CRuby prints `global: 0`. A class variable and a class-level instance variable filled the same way are wrong in the same 22 turns of 2,000, and a constant written once (`K = span(7)`) reads wrong in 1,972 of 2,000. With `SPINEL_GC_STRESS=1` the global is wrong in 1,967.

A String Range sits in its file-scope slot by value and carries two GC strings. The lines `codegen_program` writes into `sp_mark_user_globals` mark a slot that is a String, a boxed value or a reference, and a String Range is none of them: nothing marked its ends. The four loops that write those lines now share one function, `emit_static_slot_mark`, which marks each end of a String Range as `emit_class_scan` does for an instance variable.

Cost: two `sp_mark_string` calls a slot a mark (callgrind on master a2bd8900, 300,000 stores into a global beside a constant: 166,373,811 to 166,476,154 with gcc, 172,360,194 to 172,462,523 with clang). A class or a Struct with a String Range instance variable or member has a class-level slot of that name, so its program gains the two mark lines too. Every other program gets the C it had; optcarrot's C is unchanged.

Not changed: a slot whose two ends are both made in the assignment (`$r = ("a#{i}".."z#{i}")`, `R1 = ("m" + 1.to_s.."m" + 3.to_s)`) loses the first before the slot is written, which "A String Range made on the spot keeps its ends, made in order, until it is read" cures. The two fixes are independent and such a slot needs both, in either order: over 2,000 turns that global is wrong in 13 in a plain run on master and with that fix alone, in none in a plain run and in 8 at `SPINEL_GC_STRESS=1` with this one alone, and in none at any setting with both. Under `SPINEL_GC_STRESS=2`, `inspect` of a String Range in one of these slots stopped on master before the read; it now reaches the fault "A String Range's inspect holds its Strings while it builds the text" cures and prints the wrong line the same Range prints from an Array element.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (equal under CRuby 4.0.7 but for the line of the 2,000-turn section, which was made with CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: # (nothing)
