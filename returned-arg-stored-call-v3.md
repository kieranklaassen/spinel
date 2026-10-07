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
- `--share-strings`. The stored call is a copy there too (`q << id(u); u << "z"; p q` prints `["u"]` with the flag), and it is left as the flag's own open case: under the flag the route's question holds for a local that only shares its handle through the method's parameter, so it would refuse `q << id(u); p q` with nothing mutated, and the form with a local between compiles and is right there.

## Measured

On master 5390d300, over 3,989 generated programs (11 methods, 22 ways into a container, 14 things done afterwards, 6 kinds of argument), each with its twin that puts a local between (`v = id(u)`, then the store of `v`):

- 1,674 are refused that master compiles, all in the route's sentence; no other decision changes.
- 1,472 of them are wrong on master: 1,399 print other content than CRuby, 3 answer `equal?` false, 65 crash and 5 do not build (a stored call with a receiver whose element is mutated: a fault of its own, refused here because the argument's variable is read).
- 202 answer as CRuby does today: in 118 the variable is changed before the store and not after it, in 52 a `[]=` puts the call into a container that is not read again, and in 32 the method appends to its parameter before answering it and what follows fits the buffer or changes nothing. A second, wider set of the same shapes (8,630 refused, 1,500 of them run) has 31 right in 100 and adds two kinds: only the container's size is read after the change, or the change is a `setbyte`.
- Master refuses the twin of every one of the 1,674, the 202 among them, in the same sentence.
- With `--share-strings` no decision changes.
- `tools/cident.sh`: 6357 identical, 0 differ, 0 refusal changes. `tools/refusals.sh`: 540 records, the 12 added lines are the three new reject tests'. `make reject-test` and `make share-strings-test` pass.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (not compared here: the gate compares it)
- [ ] Depends on: #
