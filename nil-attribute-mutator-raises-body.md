<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A mutator called through an attribute reader on a String attribute that is nil died with SIGSEGV, or did nothing.

```ruby
class Note
  attr_accessor :text
  def initialize; @text = +"ab"; end
end
n = Note.new
n.text = nil
n.text.upcase!     # master: SIGSEGV. CRuby: NoMethodError
n.text << "c"      # master: nothing happens. CRuby: NoMethodError
```

With an Array attribute (`@text = ["ab"]`) the same `n.text << "c"` raises NoMethodError on master: the call plan's nil target tests the receiver. A String slot a mutator reaches through its reader is an `sp_String` handle, and the reader's call is typed `TY_STRBUF`: `nf_call` (`src/analyze_nil.c`) kept no nil fact for a call of that type, and `cplan_nil` gave a handle a call renders no nil target, because the target binds its receiver as a value and a mutator on that copy would miss the slot. An attribute reader's call on self, a local or another such reader (`cplan_nil_slot_reader`) now carries its ivar's fact, and its nil target tests the handle in the slot, as a local's handle is tested. The source rule is unchanged: the test is there only for a nil the program writes into a slot `initialize` sets, and a slot the fact proves not nil keeps its C.

Cost, by callgrind on master 5390d300: 400,000 `r.x.replace("z")` and 1,000,000 `r.x << "z"` on an attribute the program may set to nil take the same instructions with and without the test, within 700 of 33,465,029 and within 2 of 88,795,364: the mutator's own test of the handle takes it in.

`tools/cident.sh` against master 669ffd90: 6,361 identical, 1 differ, 0 refusal changes, of 6,362: this test.

Not here: a class with no `initialize` that sets the attribute (`class Note; attr_accessor :text; end`). The fact's source there is the ivar's, which the plan leaves untested by its stated rule, so the same two lines still crash or do nothing, as `r.a = nil; r.a.push(2)` on an Array attribute of such a class does on master. Also not here: a chained append (`n.text << "d" << "e"`), which still does nothing, and a reader called on a receiver that runs code (`make.text << "c"`).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
