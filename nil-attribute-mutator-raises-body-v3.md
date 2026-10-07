<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A mutator called through an attribute reader on a String attribute that is nil died with SIGSEGV, or did nothing. The cure costs an append on self (`text << "z"` in a method) 1 to 3 instructions where the program writes nil into the attribute; every other call measured costs nothing.

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

With an Array attribute (`@text = ["ab"]`) the same `n.text << "c"` raises NoMethodError on master: the call plan's nil target tests the receiver. A String slot a mutator reaches through its reader is an `sp_String` handle, and the reader's call is typed `TY_STRBUF`: `nf_call` (`src/analyze_nil.c`) kept no nil fact for a call of that type, and `cplan_nil` gave a handle a call renders no nil target, because the target binds its receiver as a value and a mutator on that copy would miss the slot. An attribute reader's call on self, a local or another such reader (`cplan_nil_slot_reader`) now carries its ivar's fact, and its nil target tests the handle in the slot, as a local's handle is tested. The source rule is unchanged: the test is there only for a nil the program writes into a slot `initialize` sets.

The fix applies where no argument of the call can run code: each is a literal or a plain read, and the call has no block (`nf_inert_args`). The slot is tested, and read again by the call, behind the arguments, and CRuby takes the receiver ahead of them: after `n.text << n.swap`, where `swap` rebinds the attribute, the append has gone to the String the reader gave first. A call with any other argument compiles to the same C as before.

Cost, by callgrind on master 759d120f, 1,000,000 appends, instructions before and after: `text << "z"` on self, the method called once an append, 112,798,593 and 114,798,647 with gcc, 109,762,384 and 111,762,408 with clang; the loop inside the method, 87,798,619 and 88,798,618 with gcc, the same with clang; `text << s` with a local, 3 an append with both. `r.x << "z"` and `r.x.replace("z")` take the same instructions within 28. `r.x << tail(i)`, an Array attribute, and a slot no line sets to nil compile to the same C.

`tools/cident.sh` against that master: 6,428 identical, 1 differ, 0 refusal changes, of 6,429: this test.

Not here: a call with an argument that runs code (`n.text << tail`, `tail` a method), and a reader's String taken into a local first (`x = n.text; x << "c"`): on a nil attribute both still do nothing. A class with no `initialize` that sets the attribute, a chained append (`n.text << "d" << "e"`), a reader on a receiver that runs code (`make.text << "c"`), and `q&.text << "c"` on a nil `q` are as before too.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
