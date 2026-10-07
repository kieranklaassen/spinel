<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Depends on the pull request that refuses a String instance variable assigned from another and mutated in place: this is one commit above it, and it lifts three of that refusal's cases under `--share-strings` (below).

Under `--share-strings`, a variable that keeps the answer of a call changing its receiver in place held a second String:

```ruby
class Kept
  def initialize(s) = @s = s
  def go
    @r = @s.concat("x", "y")
    @s << " and forty more bytes, so that the buffer has to move, and then some more of them"
    p @r.size      # CRuby 85, Spinel with --share-strings 4
  end
end
Kept.new(+"ab").go
```

`concat` answers its receiver, and the rule already puts `@r` in `@s`'s class and makes its slot the shared handle. The write then filled that slot with `sp_String_new_shared(<the call's bytes>)`, a new String, so a later change through one name did not reach the other.

The write now takes the receiver's handle. Where the value is `concat`, `<<`, `prepend`, `replace` or `clear` on a variable that holds the handle (through `<<` and `concat` links), and the rule's facts have the call's value and that variable in one class, the call is emitted under the handle mark, where its emitter already answers the receiver itself (the arm `r = obj.buf << x` takes). A local's, an instance variable's and a global's write take it.

The sharing pass is not changed: it gains no route, no name and no mark, and its own statistics (`SPINEL_SHARE_STATS`) are the same for every program measured. The emitter asks its facts with `share_route_defer`, as `refuse_string_copy_routed` does. Without the flag the generated C is unchanged.

The three refusals lifted: the pull request beneath refuses `@t = @s.replace(x)`, `@t = @s.prepend(x)` and `@t = @s.clear` under the flag when one name is changed and the other read, because the write copied there and the copy showed. That was right there. With this write the two names are one String, so under the flag those three are left to the rule, as a bang's kept result already is. Without the flag they stay refused.

Not here, left as they are under the flag:

- the answer kept in a class variable, in a global whose slot is a box, through `||=`, an attribute writer, a conditional's arm or a multiple assignment, or as an Array element (refused already);
- `insert`, `force_encoding`, `to_s`, `itself`, `concat` with no argument, and a bang method on an instance variable (`@r = @s.reverse!`): the rule shares the slot and the write still fills it from bytes. Their emitters have no arm that answers the handle;
- `prepend` with more than one argument and `append_as_bytes`, which the rule does not put in the receiver's class: the slot is no handle.

## Measured

On master d02a49fb, against the pull request beneath and against master, over 13,746 generated programs: the kept answer of `concat`, `prepend`, `bytesplice` and `call || @s` with a literal-set and a parameter-set receiver (1,554 and 444); an instance variable assigned through a call that answers its receiver (2,620, 744 where both names are handles already, and 26 more); each of those again with `$` for `@`; and 2,970 written for this change: eleven calls over six receiver shapes (a variable, in parentheses, behind one or two `<<`, behind `concat`), kept in a local, an instance variable and a global, in a class, a method and the script body, with a later change through either name, an identity question, or none.

- Without the flag the decision and the C of every program are those of the pull request beneath.
- Under the flag 417 programs the pull request beneath refuses now build, and 1,638 more change C. Run plain and at `SPINEL_GC_STRESS=2`: all 417 answer as CRuby does (29 of them raise IndexError on an emptied String, as CRuby does). Of the 2,055, master answers as CRuby in 466 and this branch in 2,040; none that was right on master or beneath is lost.
- The 15 still wrong print what master prints: a later `clear` through the kept instance variable is lost, with or without this change. At stress 2, 46 abort in `insert` or `[]=` on a shared handle, on master and here alike. Neither is this write's.
- `tools/cident.sh` without the flag against the pull request beneath: 6406 identical, 0 differ, 0 refusal changes. `make share-strings-test` passes with the new `test/share/share_strings_kept_mutator_result.rb` (eight programs; the pull request beneath refuses it, master prints eight of its eleven lines wrong); `make reject-test` and `tools/refusals.sh` (538 records, none changed) pass.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (not compared here: the gate compares it)
- [ ] Depends on: # (the pull request that refuses a String instance variable assigned from another and mutated in place)
