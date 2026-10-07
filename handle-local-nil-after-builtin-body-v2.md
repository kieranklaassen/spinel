## What this changes

A String local held as a handle died with SIGSEGV when it was read after a builtin call answered nil for it.

```ruby
def greeting
  who = ENV["NO_SUCH_VARIABLE"]
  return "nobody" if who.nil?
  who << ", "
  who << "hello"
  who
end
puts greeting     # before: SIGSEGV. CRuby: nobody
```

The two appends make `who` an `sp_String` handle, and ENV's miss leaves it NULL. The local's read tests the handle only where the nil fact says the local may be nil, and `nf_call` (`src/analyze_nil.c`) took every String a builtin call answers as not nil, except a container's picks and a String's slice. It now answers may-be-nil for a String's bang method that changed nothing (the builtin table's `BOPF_SELF_OR_NIL`), for ENV's `[]`, `fetch` and `delete`, a MatchData's `[]` and `Regexp.last_match(n)`, `gets`, and an IO's `getc` and `read(n)`; `bsearch` joins the picks. None of these is a nil the program writes, so no call gains a guard: only the handle's read changes, and nothing changes under `--share-strings`, whose read already tests the handle.

`tools/cident.sh` against the pull request this sits on (the one that makes a String handle local's read test the nil fact, on master ae2c38c7): 6,342 identical, 1 differ, 0 refusal changes, of 6,343: this test.

Not covered: a call on such a handle (`who.size`) still crashes, since a nil the fact cannot bound is left unguarded; a block's String value through `then`, a Proc's call or `catch`, a Struct's member read by index, a StringIO's `read(n)` and an empty String Range's `min` are still taken as not nil.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
