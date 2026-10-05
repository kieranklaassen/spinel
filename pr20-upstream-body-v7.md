<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

**Before:** a String mutator on a String that left its Array or Hash by a read no sharing rule follows ran on a copy. In a statement whose value is dropped nothing read the copy either, so the statement did nothing and the container printed as it was:

```ruby
a = [+"q", +"r"]
a.find { |s| s == "q" } << "!"     # CRuby ["q!", "r"], spinel ["q", "r"]
for s in a
  s << "!"                         # CRuby ["q!", "r!"], spinel ["q", "r"]
end
x, y = a
x.upcase!                          # CRuby ["Q", "r"], spinel ["q", "r"]
p a
```

**After:** these are refused at compile time, in the words of the other String-sharing refusals: ``a String is not yet shared by reference through an Array's `find` into an in-place `<<`. Store the new String back instead (a[i] = a[i] + x)``. No sharing rule is added.

It is the Array side of bf8e8244 (a Hash's pairs), kept narrower: only a statement whose value is dropped is refused, because there the change is all the statement is for.

**How.** Twelve commits, one pass in `src/analyze.c` beside `refuse_lent_ivar_copies` and `refuse_hash_pair_string_mutations`, run once the sharing analysis has settled:

1. `refuse_dropped_container_string_change` refuses a mutator whose receiver is a call that reads one String out of an Array of Strings or a Hash whose values are typed String (`find`, `min_by`, `max_by`, `bsearch`, `slice`, an index into a constant's Array or Hash), is still a plain String, and whose statement's value is dropped.
2. The same through a local nothing else reads: the variable of a `for` over an Array, a target of a multiple assignment from one, a local written from such a read.
3. A change no run can miss is left:
   - every String the program shows going into the container is a frozen literal: the mutator raises FrozenError, as it does by every route (the line the refusal of an appending Hash value block draws, #7004, #7029);
   - the container is built where it is read (`line.split(",").first.strip!`, `for l in text.lines`, a literal of `+"q"`);
   - the container is a local written once with such a value and looked at by one read.
4. The third commit's three kinds, drawn tight:
   - a frozen literal's container counts only while its own name alone stores into it and it is handed to no other name, method or block (`b = A`, `fill(a)`, `(A << +"s")`, `H.transform_values! { }` end it);
   - a local counts only when its one write is a statement of its own (`b = (a = [...])` and `(a = [...]) << x` give the container a second holder) and its one read comes after it and runs once. A read that runs again, in a loop over a local written outside it, is left only for a mutator that cannot change what the next run reads;
   - a `map` or `Array.new` block builds new Strings only when its last statement is a `dup`, a `+`, a `*` or an interpolation and nothing in it leaves early.
5. A frozen literal's container, once more: every call made on its name is a read of an element, a call known to answer something else (`map`, `sort`, `dup`, `join`), or a call that answers the container itself (`each`, `to_a`, `itself`, a store of frozen literals). The last kind ends the exemption when its answer is kept: `x = a.to_a; x << +"s"` stored a String the mutator then changed on a copy. Any call not on those lists (`send`, a method the program gives Array) ends it too. `bytesplice` joins `[]=` and `insert` as a mutator a read that runs again does not leave.
6. `p` answers its argument, so `x = p(a); x << +"s"` is a kept answer too. `p` is a print only where its own value is thrown away: a statement, the last statement of the program, or of an arm of an `if`, a `case` or a `begin` whose own value is. `delete` and `delete_at` answer an element, and an interpolation makes a String of its own: they keep nothing.
7. The message says what to write instead.
8. Each exception reads a call by its name (`puts`, `count`, `first`, `each` under a `for`, `split`, `dup`), and the name is the builtin only while the program defines no method of that name. `def puts(x) = $out << x` kept the Array of frozen literals; a call under a name of the program's is now taken to keep what it is handed.
9. A read that can hand the String on is no exception. `fetch` with a default or a block and `find` with an `ifnone` answer a String from elsewhere; and the block of the one read of a container built new may only compare and measure (`s == "q"`, `s.size`), since `a.find { |s| b << s; s == "q" } << "!"` kept the String under `b`.
10. The advice follows the mutator: `a[i] = a[i].upcase` for `upcase!`, `a[i] = x + a[i]` for `prepend`, a changed copy stored back for the rest (`s = a[i].dup; s.insert(...); a[i] = s`).
11. A block on the mutator is part of the change. `a.find { ... }.sub!("q") { |m| m * 2 }` lost it the same way and was compiled; it is refused like the rest, as master's refusal for a Hash's pairs already does. And the advice is printed only where following it is right: `slice!` answers the piece it cut and `<<` takes a codepoint where `+` does not, so both get the changed copy and not a plain twin; the changed-copy rewrite is not printed where the Hash itself is read and a constant, a global or a call holds it, since master can refuse the copy's store by name (through `X.values.find { }` the read is an Array's and the rewrite is still printed; followed into `X[k]` on a constant's Hash, master refuses it by name). The plain twin (`h[k] = h[k].upcase`) and the `+` forms are still printed for those holders, and are right there.
12. The changed copy is no cure for `[]=` under a String or Regexp index: `s = a[i].dup; s["q"] = "Z"; a[i] = s` leaves the Array as it was on master when a constant, a global, an ivar, a parameter or an attribute holds it, since that assignment does nothing to a String that is then stored (master's own fault, not this pass's). The message ends at the mutator's name for such an index; an Integer index, two Integers and a Range keep the rewrite.

A local's reads, and a constant's reads and writes, are chained by name once and each name's verdict is kept, so the pass stays linear.

Left as it was: every read the analysis shares (`a.first << x`, `t = a[0]; t << x`, a block's parameter); `setbyte`; `scrub!` with a block, which is refused by name where it is lowered; a `concat` or `prepend` of nothing (given a block, which Ruby ignores, it is still refused: `a.find { }.concat { 1 }`, which nobody writes); a mutator whose value is used; a boxed value; a local read anywhere else or written twice.

**Write instead** the new String stored back, as the message says: `i = a.index { ... }; a[i] = a[i] + x`. The message's `a` (or `h`) is the container that holds the String, not what the read was called on: for `h.values.find { ... }`, `x.sort.find { ... }` or `x.first(2).find { ... }` the store goes into `h[k]` or `x[i]`, since a store into the call's answer changes a temporary. Of eight rewrites tried over a local, a parameter, an ivar, a global, an attribute and a constant it is the one that answers as CRuby does for all six. Every rewrite the message can print was then run as written, on master fa08b100 and on this head: 47 forms over an Array and a Hash, each held by a local, a constant, a parameter, an ivar, a global and an attribute, 564 programs. 529 answer as CRuby does (10 of them `append_as_bytes`, which CRuby 3.3.6 does not have: judged by the value printed; the 47 over a Hash behind an attribute reader were run again on master 52c5ccf7 after a reading found the generator had given the object and the key one name). 12 are `unicode_normalize`, refused by name with or without the bang. 23 are the changed copy stored into a Hash that a constant holds (14 of the 15 copy forms) or a global holds (9 of 15), which master refuses by name ("a Hash element store given a String, which no conversion keeps in its const char * slot"): the message prints no changed-copy rewrite for those holders. One rewrite was wrong when followed and is no longer printed: the changed copy for `[]=` under a String or Regexp index (item 12; write `a[i] = a[i].sub("q", x)`, right on all six holders, or `sub("q") { x }` where `x` may hold a backslash, which a replacement String reads and `[]=` does not). For a local or a parameter a change the analysis follows also works (`a.each { |s| s << x if ... }`, `a[i] << x`); `docs/limitations.md` says the same.

**The corner that remains.** Some right programs are refused. Each is a shape master refuses today in its Hash form:

- The holder is never read after the change, or only before it, and the pass cannot know: it is a parameter, an instance variable, a Struct member or a method's answer (`def shout(words); words.max_by { ... } << "!"; nil; end`). Master refuses `h.first[1] << "!"` for every such holder, read again or not (bf8e8244).
- Only the run can tell that the change did nothing: a branch the data never takes, a `strip!` that finds nothing, a `sub!` whose pattern matches nothing (with a block or without), an append of `""`, an `insert` past the end under `rescue IndexError`, a holder cleared before it is printed, a holder whose other name is only counted. Master refuses each as `h.each_value { |v| ... }` ("a String stored in a Hash is passed to an appending value block").
- A frozen literal's container handed to a method, or the container itself kept as a call's answer (`x = a.to_a`, `x = a.each { }`, a method whose last statement is `p a`, `p a and puts 1`, `p(a) rescue nil`, a `p a` that ends a block), or read through a name the program gives a method of its own (its own `puts`, an Array `count`, a `size` or an `==` in any class, a `freeze` anywhere): the mutator raises FrozenError in CRuby and on master, or changes a String nothing reads again, and is refused here. The test's cost, weighed: of 216 right programs that put an excepted statement beside a method of a listed name in a class the container never meets, 16 are refused, 11 where the method has the name of a call the statement itself makes (`==`, `size`, `first`, `find`, `max_by`, `split`, `start_with?`, `puts`) and 5 for `freeze`, which ends the frozen literal's exception whether or not the statement calls it. Master refuses the same through a Hash's pairs, whatever else the program does with the Hash. The message's rewrite is not the cure for these, since they are meant to raise; a method that ends `p a; nil` compiles.
- A local the pass cannot see is read once: printed before the change, written twice, written by a multiple assignment, or holding an interpolated String; or its one read has a block that does more than compare or measure (`puts s`). Master refuses each through a Hash's pairs.

**Still silent.** The pass asks only about the statement nothing else reads. A mutator that is the last statement of an `if`, a `case` or a method, a loop that also prints its variable (`for s in a; s << "!"; puts s; end`), two mutators in one `for` body, a change made inside a block that is handed the read's answer (`a.find { ... }.tap { |t| t << "!" }`) and every form whose value is used answer as before.

**Measured.** On the merge with master 9c4eec71: `tools/refusals.sh` passes (504 records); `make reject-test` passes; the corpus's 6,137 programs (`test/`, `benchmark/`, `packages/*/test/`) all still compile to C, none refused; the 2,621 earlier programs answer, verdict by verdict, as on the merge with 52c5ccf7. The pass runs before `mark_param_read_only_operands` (#7531); neither reads what the other writes. On the merge with master 52c5ccf7: the same three checks (6,132 programs); 2,621 earlier programs run on the last head and on this one, verdict by verdict: 2,585 the same; 36 go from wrong to right, each right on master 52c5ccf7 alone (master cured them since fa08b100); no program moves to refused, to wrong or to not building. The first ten commits, merged with master 1ed8b0fb: `tools/cident.sh`, 5,997 programs' C identical, no refusal changes, 5 differ (four only in the compiler's own revision string, one a test this branch grows); `make scale-test`: 1.71x, 4.73x, 6.08x, 4.22x, each under its limit. Neither was run again on the last two commits, which change which statements are refused and what the message says, and no C.

Of 493 small programs written to break the refusal, run on master ab9b925a and on this head, each against CRuby:

| on master | on this head | programs |
|---|---|---|
| right | right | 275 |
| silently wrong | refused by this pass | 75 |
| right | refused by this pass | 21 (the shapes above) |
| silently wrong | silently wrong | 80 |
| refused or not building | the same, one of them refused by this pass | 42 |

No program that was right answers wrong or stops building. 196 programs that change a frozen literal by every form and mutator answer as master does. Of 180 more that raise FrozenError after another use of the container's name, 170 raise as before and 10 are refused (the kept answers above); 23 more, whose method ends in `p` of its local container, are refused too. Of 230 written around a program's own methods and a read's block, run again on master fa08b100: 108 wrong on master are refused (94 answer silently wrong there, 8 raise an error CRuby does not, 2 crash, 4 answer where CRuby raises), 65 right ones are refused (the shapes above, each with its Hash twin refused by master; the twin reads the same String through the pairs, `h.find { |k, s| ... }[1]`), 29 are right on both and 22 stay wrong by routes this pass does not see. Of 42 that give the mutator a block, over seven holders: 28 silently wrong on master are refused, and the 14 whose pattern matches nothing are refused with them (the twin is refused by master for 12; for the two through a local master compiles the twin, as it does for the same statement without a block). Of 1,369 older programs two more right ones are refused, both a `gsub!` with a block: one run for what its block does, where the block gives each match back, and one on a method's answer that nothing reads again. Master refuses the twin of each.

Compile time: `make scale-test` as above. One term still grows faster than the program where a single scope holds thousands of candidate locals: 0.27% of the compile at 2,000.

Tests: thirty-nine programs under `test/reject/`: thirty-eight were a silent wrong answer before, and one, the `[]=` under a String index on the answer of `find`, raised NoMethodError at run time ("undefined method '[]=' for an instance of String"), as that assignment does on master on the answer of `find`, `min_by`, `bsearch` or `slice`; `test/string_container_read_change_kept.rb` and `test/string_container_local_change_kept.rb` hold the neighbours that still compile and print what CRuby prints; `docs/limitations.md` lists both refusals and their exceptions under "Not yet shared".

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written under CRuby 3.3.6; they print Arrays of Strings and Integers, nothing 4.0 words differently)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (no test or benchmark program's C changed)
- [ ] Depends on: #
