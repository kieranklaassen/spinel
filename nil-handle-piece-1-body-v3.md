<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A String handle local that a builtin call left nil died with SIGSEGV in the program's own nil test.

```ruby
def next_line
  line = gets
  return "end of input" if line.nil?   # master: SIGSEGV at the end of the input
  line << "!"
  line << "?"
  line
end
puts next_line                          # CRuby: end of input
```

The two appends make `line` an `sp_String` handle, `gets` leaves it NULL, and its read tests the handle only where the nil fact says the local may be nil. `nf_call` (`src/analyze_nil.c`) took every String a builtin call answers as not nil, except a container's picks and a String's slice. It now answers may-be-nil for a String's bang method that changed nothing (the table's `BOPF_SELF_OR_NIL`), a MatchData's `[]` and `Regexp.last_match(n)`, `gets`, and an IO's `getc` and `read(n)`; `bsearch` joins the picks. None is a nil the program writes, so no call gains a guard: only the handle's read changes, and only where the program tests the local before it writes through it. Every other read is one `nil_fact_unraised` keeps as it was. With `--share-strings` nothing changes: master reads the handle through a tested helper there.

Cost, by callgrind on master 8b3ba5c4: 400,000 calls of a method that reads a MatchData group into such a local, tests it for nil and appends twice take 1,856,737,707 instructions before and 1,856,738,782 after. A handle no listed builtin feeds compiles to the same C.

`tools/cident.sh` against the pull request this sits on, on master 8b3ba5c4: 6,369 identical, 1 differ, 0 refusal changes, of 6,370: this test.

Not here: an append on such a local with no nil test ahead of it (`line = gets; line << "!"; p line`) dies at the read as on master, where CRuby raises NoMethodError at the append; so does a local the program appends to before the builtin's answer is assigned to it, since the fact does not follow the order. A call nil does not answer (`line.size`, `line < "a"`) still crashes. ENV's reads are left as they were: an append on an ENV value is a FrozenError in CRuby. `Array(line)`, `[*line]`, `line.eql?(nil)` and `line.equal?(nil)` answer as a plain String local's nil does on master (`[nil]`, false), which is not CRuby's answer. `$~[2]` in a method after a match made at the top level answers nil, as it does for a plain local on master; CRuby raises NoMethodError there, since `$~` is nil in the method.

Depends on the pull request "A String handle local that may be nil reads as nil".

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
