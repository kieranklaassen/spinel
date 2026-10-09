<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A method that answers its String parameter hands the caller the one object. The returned-argument route of `refuse_string_alias_copies` refuses that where the result is kept in a variable (`v = id(u)`) or mutated (`id(u) << x`). Stored straight into an Array or a Hash the call was asked nowhere, and the element held a copy silently:

```ruby
def id(x) = x
u = +"u"
q = []
q << id(u)
u << "z"
p q        # CRuby ["uz"], Spinel ["u"]
```

The route's two questions are now asked for a call that is the value of a push or of `[]=`, or an element of an Array or Hash literal assigned to a variable, in the route's sentence, unchanged:

- the variable passed in is mutated in place and the container is read (`refuse_string_alias_copies`);
- an element is mutated in place and the variable is read (`strbuf_demand_store_leaf`, beside the refusal of `a << (s << "y")`): the element would be a fresh handle over a copy.

A method that appends to its parameter before answering it looks right only while the next append fits the buffer, and is refused the same way:

```ruby
def pass(s); s << "p"; s; end
u = +"u"
q = []
q << pass(u)
u << "0123456789012345678901234567890123456789"
p q        # CRuby ["up0123456789012345678901234567890123456789"], Spinel ["up"]
```

Not here, still copies and not refused:

- a constructor argument (`Box.new(id(u))`), `insert`, `concat`, and a literal that is not assigned to a variable (`show([id(u)])`). One of the tests on master prints such a literal where it stands (`p [m2(s), s, m2(1), m2(t), t]` in `test/poly_narrowed_append_value.rb`) and is right;
- a literal that reaches its variable another way: nested (`q = [[id(u)]]`), under a condition (`q = c ? [id(u)] : []`), through `||=` or `+=`, in a multiple assignment (`q, r = [id(u)], 1`), and `Array.new(1) { id(u) }`. Each still prints `["u"]` in place of `["uz"]`, and the list is not whole;
- a push whose value is an assignment (`q << (w = id(u))`): the element is still the copy;
- the caller's side. Master now refuses a kept or mutated result when the argument is the enclosing method's own parameter and the caller reads its variable again. A stored call is asked the route's two older questions only: `def entry(data); q = []; q << id(data); q[0] << "y"; end`, then `entry(s); p s`, still prints "u" where CRuby prints "uy";
- `--share-strings`. Nothing is asked there: the stored call is the rule's. On master ed986127 the rule shares the element (`q << id(u); u << "z"; p q` prints `["uz"]` with the flag) or refuses the call in a sentence of its own.

## Measured

On master 5390d300, over 3,989 generated programs (11 methods, 22 ways into a container, 14 things done afterwards, 6 kinds of argument), each with its twin that puts a local between (`v = id(u)`, then the store of `v`):

- 1,674 are refused that master compiles, all in the route's sentence; no other decision changes.
- 1,420 of them are wrong on master: 1,347 print other content than CRuby, 3 answer `equal?` false, 65 crash and 5 do not build (a stored call with a receiver whose element is mutated: a fault of its own, refused here because the argument's variable is read).
- 254 answer as CRuby does today: in 154 the variable is changed before the store and not after it, in 52 a `[]=` puts the call into a container that is not read again, and in 48 the method appends to its parameter before answering it and what follows fits the buffer or changes nothing. A second, wider set of the same shapes (8,630 refused) adds two kinds: only the container's size is read after the change, or the change is a `setbyte`.
- Master refuses the twin of every one of the 1,674, the 254 among them, in the same sentence.
- With `--share-strings` no decision changes.
- On master 70ff7a36: the same 1,674 are refused and no other decision changes, with the flag or without. Master's C for the 1,674 is no longer 5390d300's; run again on 70ff7a36, each answers as it did. On master 47225b48 the same held.
- On master 9c57b440, which this commit sits on: the same 1,674 are refused, no other decision changes, the 264 below are decided as on ed986127, and with the flag every decision and every sentence is master's (the flag builds 3,456 of the 3,989 there and refuses 533). The 1,674 were last run again on master ed986127, plain and at `SPINEL_GC_STRESS=2`, where each answered as it did. `tools/cident.sh`: 6657 identical, 0 differ, 0 refusal changes. `tools/refusals.sh`: 562 records, the 12 added lines are the three new reject tests'. `make reject-test`, `make share-strings-test`, `make int-min-test` and `make infer-test` pass. On master 9c57b440 each of the three reject tests builds and prints other content than CRuby.
- Beside master's newer arm, on ed986127: 264 more programs in which the argument is the enclosing method's own parameter (ten ways to store the call, a change through the parameter, an element or a kept result, four reads, a caller that reads its variable again or passes a fresh String). Master refuses 54 and the compiler those and 68 more, on the same line and in the same sentence wherever both refuse. Of the 68, 61 print other content than CRuby on master and 7 answer as CRuby does: 4 put the call with `[]=` into a container that is not read again, and in 3 an element is changed while the parameter is read only as the argument of another such call, whose result nothing prints. The two arms do not meet in one statement: master's ask a variable's write whose value is the call and a mutator whose receiver is the call; these ask a call that is a push's argument, the value of `[]=` or a literal's element. Of the 142 still built, 23 are wrong on master and stay so: 10 by the caller's side, 12 by a push whose value is an assignment, and one push of a mutated result, which is master's own.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this commit in a Linux container, with gcc 13.3 and clang 18.1: the build, `ruby tools/gate.rb check` with the change staged, `tools/refusals.sh`, `make reject-test`, `make share-strings-test`, `make int-min-test`, `make infer-test`, the new test with both compilers plain and at `SPINEL_GC_STRESS=2` and by the gate's rule for one program in both corpus lanes, which both pass it, and `tools/cident.sh`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (compared with CRuby 3.3.6 run with that flag)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is byte-equal to master's)
- [x] Depends on: nothing
