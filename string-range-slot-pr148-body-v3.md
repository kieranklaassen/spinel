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

prints `0: j44..j45` and `161: j284..j285` before `done` in a plain run (`spinel diff`: output-diff). CRuby prints `done` alone. A constant, a class variable and a class-level instance variable were marked by nothing either.

A String Range sits in its file-scope slot by value and carries two GC strings. The lines `codegen_program` writes into `sp_mark_user_globals` mark a slot that is a String, a boxed value or a reference, and a String Range is none of them: nothing marked its ends. The four loops that write those lines now share one function, `emit_static_slot_mark`, which marks each end of a String Range as `emit_class_scan` does for an instance variable.

Cost: two `sp_mark_string` calls a slot a mark (callgrind on master c6bbdfbc9, 300,000 stores into a global beside a constant: 166,367,600 to 166,469,971). A class or a Struct with a String Range instance variable or member has a class-level slot of that name, so its program gains the two mark lines too. Every other program gets the C it had; optcarrot's C is unchanged.

Not changed: a constant whose two ends are both made in the assignment (`R1 = ("m" + 1.to_s.."m" + 3.to_s)`) loses the first before the slot is written, which is #<fork PR 94>, and this depends on it. Under `SPINEL_GC_STRESS=2`, `inspect` of such a Range stopped on master before the read; it now reaches the fault #<fork PR 51> cures and prints the wrong line the same Range prints from an Array element.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (equal under CRuby 4.0.7)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: #<fork PR 94> (a constant whose two ends are both made in the assignment loses the first before the slot is written)
