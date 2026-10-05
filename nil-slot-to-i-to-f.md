<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
class Card
  def list = (@list ||= [1])
  def count = @list.to_i
end
p Card.new.count          # 0 in CRuby, NoMethodError here
```

nil answers `to_i` and `to_f`; Array, Hash and a class of the program's own have neither, so the call fell to the gate's raise whatever the slot held ("undefined method 'to_i' for an instance of Array"). The pull request this one depends on answers the other names only nil has (`to_a`, `to_h`, `&`, `|`, `^`) by testing the slot; these two were left out because they are typed Integer and Float for any receiver, where the gate's raise is the other of its two spellings.

`null_slot_nil_only_call` takes the two names, and `emit_null_slot_nil_only` answers 0 or 0.0 for a NULL in the call's own type and raises as before for any other value. A String answers both itself, and a class with a `to_i` or a `to_f` of its own keeps it; neither is tested. One commit: src/analyze.c +13 -6, src/codegen_call.c +27 -13.

For an object slot, the later step that issue #7444 proposes would cover the same ground; for an Array or a Hash slot it would not.

**Measured.** The 672 `to_i` and `to_f` programs of the 7,392 the other pull request describes (six kinds of slot, the nil reaching it seven ways, the call in four positions, each with a twin whose slot holds a value), master c6bbdfbc9 against this commit above it, gcc, plain and under `SPINEL_GC_STRESS=1` and `2`, CRuby 3.3.6 as the reference: of the 336 with a nil, 184 are right on master and 336 here; the 152 raised. The 336 twins each print what they printed.

**Cost.** None for a program that ran: the call raised whatever the slot held.

**Generated C.** `make cident` against the commit below it, on 5c2dea51: `6080 identical, 3 differ, 0 refusal changes`. The three are the new test and two tests of the pull request below (`nil_slot_nil_only_names.rb`, `nil_slot_nil_only_nested.rb`), whose raise arms gain a parenthesis; they pass. `tools/refusals.sh`, `reject-test` and `make nil-check-test` pass.

**Test.** `test/nil_slot_to_i_to_f.rb` raises NoMethodError on master. It passes with gcc and clang, plain, under `SPINEL_GC_STRESS=1` and `2`, and under `SPINEL_GC_MINOR=1 SPINEL_GC_VERIFY_GEN=1`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; it prints Integers, Floats, Symbols, class names and one String)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (the pull request "A nil held in a typed slot answers nil's own to_a, to_h, &, |, ^ and is_a?")
