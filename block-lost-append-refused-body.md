<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A block parameter the body assigns is renamed (`|k__bpin| k = k__bpin`), so `k` is a local that is assigned again. `dyn_lit_bits` leaves the appends of such a local out, no call pulls the caller's variable into the shared handle, and the block grows a copy:

```ruby
def run(s) = yield(s)
s = +"a"
run(s) { |k| k ||= +"z"; k << "x" }
p s
```

```
spinel diff: output-diff
-"ax"
+"a"
```

A proc and a lambda lose the append the same way through a local of their own (`->(k) { t = k; t ||= d; t << x }`). `--share-strings` prints `"ax"`.

`dyn_lit_lost` reads the body's statements in order and answers the parameters appended to through such a local: it holds the parameter from `t = k` until a statement gives it another value, or an `if`, an `unless` or a `case` does on every arm, an else among them. The answer travels beside the append bit (`DynReach.lost`) and is asked where a String variable is already refused or shared: `f.call(s)`, `f.(s)`, `f[s]`, a yield into `&f`, and a call with a literal block to a method that yields its parameter. The call is refused in the route's own sentence. The same call site refuses a String variable in an Array literal the method yields with a splat (`def y(a) = yield(*a)`; `y([s]) { |k| k << "x" }`), a copy for a plain append too.

2,256 programs (six kinds of argument, seven call forms, block bodies that assign the parameter or a local), master against this:

| on master | with this | programs |
|---|---|---|
| wrong | refused | 401 |
| does not build | refused | 32 |
| right | refused | 0 |
| right | right, master's C byte for byte | 952 |
| refused | refused | 429 |
| wrong, no build or a crash | the same, master's C | 442 |

Under `--share-strings` nothing changes: the same 2,256 give master's answer and master's C (`refuse_lost_append` stands down there; what the local holds is the rule's to say). The four reject tests are in `test/share/reject.list` with CRuby's answers.

**Not in this change.** Of the 442, 343 are wrong on both (35 only in the text of an error). Still a silent copy: an Array element as the argument, a String that reaches the local through a conditional value, a second local or a call (`t = c ? d : k`, `u = t`, `t = k.itself`), an arm that takes the String back (`o = k; if c then k = +"p" else k = o end`), an Array variable splatted into the yield, and the iterators (`each`, `then`, `tap`).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
