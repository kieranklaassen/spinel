<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A fix with one cost, said first. At run time, where it applies, the guarded arm has the C the `when` arm has on master and costs what that costs. Callgrind, 500,000 passes of `r.each { |e| if e.is_a?(String); t = e; t.upcase!; end }` over `r = [n.to_s, 5]` with `p r` after the loop: 145,218,096 instructions before, 222,229,876 after; with `case e when String` master takes 225,729,877. Master prints that program right only because upcasing a String of digits changes nothing; with a letter in it master's line is wrong. The same loop without the `p r` keeps master's C: where nothing else reads the String, this change stands aside. At compile time each question is asked once for a local and read off that local's own chains, and the first is whether the assigned value is the guarded local at all. `spinel -S` under callgrind, before and after, the same C on both sides: a guard's arm of 400 pairs `x = i; y = x`, 658,727,467 and 658,908,758, of 800 pairs 2,143,337,535 and 2,143,699,410; one guarded local handed to 400 names, 347,441,770 and 347,607,447, to 800 1,100,528,551 and 1,100,858,466; a chain of 400 names, 5,572,011,486 and 5,572,161,678, of 800 36,425,663,537 and 36,425,963,591; 1,000 methods that each guard and assign, 8,242,478,891 and 8,242,701,829, 2,000 17,142,842,574 and 17,143,845,001, 4,000 35,345,192,721 and 35,347,756,473. A program with no guard at all runs no line of this change; 1,000 such methods take 3,495,021,424 and 3,494,540,628, 2,000 7,664,527,546 and 7,663,983,693: layout, measured. Where the cure applies the local is boxed as it is under `when`: 400 such arms in one scope, 3,690,018,126 before and 4,997,736,694 after, and master takes 4,239,832,642 for that program written with `when`; 1,000 methods of one such arm each, 32,099,159,916 before and 32,183,774,307 after, and 2,000 of them 104,790,608,798 and 104,958,620,921.

```ruby
r = [+"ab", 5]
e = r[0]
if e.is_a?(String)
  t = e
  t << "z"
end
p r
```

prints `["abz", 5]` in CRuby and `["ab", 5]` here. With `--share-strings` it is right, and without the flag it is right under `case e when String`.

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-["abz", 5]
+["ab", 5]
```

The Array keeps this String as its handle, since an element is changed in place. The guard narrows the reads of `e` in its arm to String, and a narrowed read unboxes: `t = e` took the bytes out of the handle, t was a String of its own, and the append grew that one. The `when` arm narrows nothing, so there t is boxed as e is and `lift_poly_alias_reads` makes the two names one String. Under `--share-strings` the store lifts the box itself (`strbuf_boxed_local`), so nothing here applies to that build: its C is master's.

`isa_mark_reads` already leaves an Array read boxed where it is handed on, because the narrowed read is a copy. It now leaves a String read boxed where it is the value of a local's only assignment, a statement, and four things are shown by the program's text. Anywhere else the read is narrowed as before and the C is the C it was.

1. The box holds the handle (`isa_guarded_is_handle`). The guarded local is the element an Array's iterator binds (`each`, `map`, `collect`, `select`, `filter`, `reject`) or is assigned once, an element read (`r[i]`, `r.fetch(i)`, `r.first`, `r.last`), and the Array is a local that keeps handles. It does where every use of that local is on a list (`isa_holder_keeps_handles`): a statement that assigns an Array literal or `Array.new(n)`; the receiver of an element read, of `size`, `length`, `empty?` or `inspect`; the receiver of an iterator with a block, `each` as a statement; the receiver of a statement that stores a value kept as its handle (`r[i] = v`, `r << v`, `r.push(v)`); an argument of a `p`, `puts` or `print` statement.
2. The box serves every use of the assigned local (`isa_alias_served`): the receiver of a String mutator that is a statement (`t << x`, `t << x << y`, `t.upcase!`), the receiver of a call that is an argument of a `p`, `puts` or `print` statement (`puts t.size`), or such an argument itself.
3. The String is read under another name (`isa_read_again`): the guarded local is read beside its guards and the assignment, or its Array is read in a second place.
4. No call these read by its name could be the program's own (`isa_program_may_own`, and the mutator's or the printed call's own name). That is asked of the program as written, by master's `an_prog_never_gives`: no def and no Symbol of such a name, and no site that names, makes or loads a method by something the text does not spell (a computed name, text evaluated, a file left unread, a module mixed in). The second test is such a program: master runs it right, and so does this change.

Of 3,932 programs that read a holder's String under the guard and change it in place (sixteen ways to build the holder, fourteen kinds of String, eight ways to reach the element, eleven guards and mutators, at top level, in a method and in a block), 720 go from a wrong line to right and 48 from a wrong line to CRuby's FrozenError (a String literal in a literal holder, which master changed and printed); 48 that were right have other C, the cost above (each upcases a String of digits); 2,819 have the C they had and 297 are refused before and after; none that was right changes its answer. With `--share-strings` all 3,932 have the C they had. `tools/cident.sh`: 6752 identical, 1 differ (the first new test); with `--share-strings` 6752 identical, none differ, 1 refused before and after; no compile reached the script's time or memory bound. `tools/refusals.sh` pass (592 records); `make reject-test`, `make share-strings-test`, `make int-min-test` and `make gc-stress-test` pass.

Not in this change, each as on master without the flag:

- a String that came in as a method's parameter or as one arm of a conditional (`e = c ? s : 5`): what the caller or the arm holds is not known to be a handle;
- an Array used in any way that is not on the list: one a call hands back or answers (`q = p(r)`, `q = r.each { }`, the last expression of a method), one written as a value (`q = r = [...]`), one read by `fetch` with a default or by a slice, a parameter, a captured local; and a Hash. Under a second name a plain String may be put in it; such a program is right on master while the append fits the String's spare room and wrong when it does not (`t << ("z" * 40)`), before and after;
- an Array that keeps a plain String (one born `[]`, filled by index and read by `r[0]`): the same;
- an element bound by `each_with_index`, `each_with_object` or a `for`;
- a local used in any way that is not on the list: as another call's operand (`("a".."b").cover?(t)`, `x.casecmp(t)`, `"x" + t`), as a Range's end, under `case`, in an interpolation, under a second name (`u = t`), handed to a method, as the receiver of a call with a block or of a call whose value is used (`n = t.size`). A boxed String does not answer as a String does in each of these on master, so the local keeps the String it had;
- a local assigned in a second place: boxed, it is boxed for its whole scope;
- a String nothing else in the scope reads (the Array read in one place and the guarded local only by its guards and the assignment); a loop that runs that one read again is not counted, and is as on master;
- any program that has, or could come by, a method of its own named as a call the proof reads (`each`, `[]`, `first`, `p`, `[]=`, `<<`, `new` and their kin, the mutator, the printed call): one with a def or a Symbol of such a name, or one that computes a method's name, evaluates text, leaves a file unread or mixes a module in (`include Comparable`).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [x] Depends on: # (nothing)

No `docs/limitations.md` entry is owed: no entry names this construct, and the change adds and lifts no refusal.
