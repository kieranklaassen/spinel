<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A fix with two costs, said first. At run time, where it applies, the guarded arm has the C the `when` arm has on master and costs what that costs. Callgrind, 500,000 passes of `r.each { |e| if e.is_a?(String); t = e; t.upcase!; end }` over `r = [n.to_s, 5]`, a program master answers right because the `upcase!` changes nothing: 145,218,240 instructions before, 222,229,939 after; with `case e when String` master takes 225,729,926. The String is the Array's own after the change, so the cost is not cut. At compile time the proof is one walk a scope: `spinel -S` on 4,000 methods that each guard and assign, 35,288,510,103 instructions before and 35,342,455,837 after; on one scope of 400 guarded appends over a Hash the proof does not take (the C is the same), 2,138,128,355 before and 2,164,452,341 after. Where the cure applies the local is boxed as it is under `when`: 400 such arms in one scope, 3,631,958,064 before and 4,936,046,075 after, and master takes 4,182,228,034 for that program written with `when`; 1,000 methods of one such arm each, 32,069,708,832 before and 32,154,644,240 after, and 2,000 of them 104,730,850,921 and 104,899,540,885.

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

`isa_mark_reads` already leaves an Array read boxed where it is handed on, because the narrowed read is a copy. It now leaves a String read boxed where it is the value of a local's only assignment, that local is changed in place as a String (itself, under a name it is assigned to, or by a method it is handed to whose parameter is), and the box is known to hold the handle: the guarded local is the element an Array's iterator binds (`each`, `map`, `select` and their kin) or is assigned only an element read (`r[k]`, `r.first`, `h.fetch(k)`), and the Array or Hash is a literal, or a local that is written only as a literal or `Array.new(n)` and otherwise only read, printed, or stored into with a value it was asked to keep as its handle (`isa_holder_keeps_handles`).

Everywhere else the read is narrowed as before and the C is the C it was. A holder that keeps a plain String hands out that String itself (a Hash filled by `h[k] = v` and read by `each_value`, an Array born `[]`, filled by index and read by `r[0]`): there the narrowed read is no copy, an append that fits the String's spare room shows through the holder, and a handle made at `t = e` would be the copy. A local assigned in a second place keeps the narrowed read too: boxed, it is boxed for its whole scope.

The proof reads its calls by their names: `r.each`, `r[k] = v`, `Array.new(n)`, `p r`. A method of the program's own under one of those names may put a plain String into the holder behind them (a top-level `def p(a)` that does `a.concat(["s"])`), so the read is narrowed as before in any program that could have one (`isa_program_may_own`). That is asked of the program as written, by master's `an_prog_never_gives`: no def and no Symbol of such a name, and no site that names, makes or loads a method by something the text does not spell (a computed name, text evaluated, a file left unread, a module mixed in). The second test is such a program: master runs it right, and so does this change.

Two more kinds of local keep the narrowed read though they are changed in place. One that is the receiver of a call with a block: a boxed String's `split(x) { }` raises NoMethodError. And one whose guarded value is only what a method of the program returned, read nowhere else (`e = pick(i)`): the box does not reach that String either.

Of 3,932 programs that read a holder's String under the guard and change it in place (sixteen ways to build the holder, fourteen kinds of String, eight ways to reach the element, eleven guards and mutators, at top level, in a method and in a block), 1,142 go from a wrong line to right and 69 from a wrong line to CRuby's FrozenError (a String literal in a literal holder, which master changed and printed); 65 that were right have other C, the cost above; 2,359 have the C they had and 297 are refused before and after; none that was right changes its answer. With `--share-strings` all 3,932 have the C they had. `tools/cident.sh`: 6708 identical, 1 differ (the first new test); with `--share-strings` 6709 identical, none differ; no compile reached the script's time or memory bound. `tools/refusals.sh` pass (580 records); `make reject-test`, `make share-strings-test`, `make int-min-test` and `make gc-stress-test` pass.

Not in this change, each as on master without the flag:

- a String that came in as a method's parameter or as one arm of a conditional (`e = c ? s : 5`): what the caller or the arm holds is not known to be a handle;
- a holder that keeps a plain String (a Hash filled by `h[k] = v` and read by `each_value`, an Array born `[]`, filled by index and read by `r[0]`): right on master while the append fits the String's spare room, and wrong on master when it does not (`t << ("z" * 40)`), before and after;
- an element bound by `each_with_index`, `each_with_object` or a `for`;
- a constant handed to the method, a Hash's value block, `t.equal?(e)`;
- any program that has, or could come by, a method of its own named as a call the proof reads (`each`, `[]`, `first`, `p`, `[]=`, `<<`, `new` and their kin): one with a def or a Symbol of such a name, or one that computes a method's name, evaluates text, leaves a file unread or mixes a module in (`include Comparable`).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [x] Depends on: # (nothing)
