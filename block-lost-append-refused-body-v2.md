<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**The cost first: 20 of the 560 programs of the second set below are right on master and refused.** They are two forms of `begin`: one whose body alone has the write (`begin; k = +"n"; rescue; n = 1; end; k << x`), and one whose rescue alone has it and always runs (`begin; n = Integer("z"); rescue; k = +"m"; end; k << x`). The walk does not read whether a statement raises: where the first body raises before its write, or the second does not raise, the same block loses the append on master.

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

`dyn_lit_lost` reads the body's statements in order and answers the parameters appended to through such a local: it holds the parameter from `t = k` until a statement gives it another value on every path. That is a write (`t = t.dup`, `t += x`, `t &&= v`, `t, j = v, w`, `t, j = f(x)` where the call reads neither name, `j = t = v`); an `if`, an `unless`, a `case` or a `case/in` with one on every arm, an else among them (a `case/in` needs none: a miss raises); a `begin` whose ensure has one, or whose body and every rescue have one; and `(t = v) << x`, whose write runs first. The answer travels beside the append bit (`DynReach.lost`) and is asked where a String variable is already refused or shared: `f.call(s)`, `f.(s)`, `f[s]`, a yield into `&f`, and a call with a literal block to a method that yields its parameter. The call is refused in the route's own sentence. The same call site refuses a String variable in an Array literal the method yields with a splat (`def y(a) = yield(*a)`; `y([s]) { |k| k << "x" }`), a copy for a plain append too.

2,256 programs (six kinds of argument, seven call forms, block bodies that assign the parameter or a local), master against this:

| on master | with this | programs |
|---|---|---|
| wrong | refused | 401 |
| does not build | refused | 32 |
| right | refused | 0 |
| right | right, master's C byte for byte | 952 |
| refused | refused | 429 |
| wrong, no build or a crash | the same, master's C | 442 |

560 more around one statement that writes the parameter (four holders, five call forms, 28 block bodies: a multiple assignment, a chained write, `&&=`, `||=`, `begin` with rescue, else and ensure, `case/in`, a write in the receiver, a loop):

| on master | with this | programs |
|---|---|---|
| wrong | refused | 92 |
| right | refused | 20 |
| right | right, master's C byte for byte | 268 |
| refused | refused | 158 |
| wrong or a crash | the same, master's C | 22 |

Under `--share-strings` nothing changes: the same 2,256 give master's answer and master's C (`refuse_lost_append` stands down there; what the local holds is the rule's to say). The five reject tests are in `test/share/reject.list` with CRuby's answers.

**Not in this change.** Of the 442, 343 are wrong on both (35 only in the text of an error). Still a silent copy: an Array element as the argument, a String that reaches the local through a conditional value, a second local or a call (`t = c ? d : k`, `u = t`, `t = k.itself`), an arm that takes the String back (`o = k; if c then k = +"p" else k = o end`), an Array variable splatted into the yield, the iterators (`each`, `then`, `tap`), a block forwarded with `&` through a second method (`def fwd(s, &b) = run(s, &b)`), and a parameter written in a nested block that does not run (`[].each { k = +"n" }; k << x`).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
