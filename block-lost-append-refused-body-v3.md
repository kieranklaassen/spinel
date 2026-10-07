<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**The cost first: the walk reads no condition and no loop as running, so some blocks that are right on master are refused.** They give the parameter another String on every path that runs, but not on every path the walk can read: a write and its append under one condition (`k = +"n" if c; k << x if c`), two complementary `if`s, a write behind `&&` or `and`, a loop that always runs (`begin ... end while false`, `while true ... break`, `for i in [1]`), and a `begin` whose body alone has the write or whose rescue alone has it and always runs. They are 32 of the 470 programs of the third set below and 20 of the 560 of the second; other forms of the kind exist. For the `begin` forms the same block with other data loses the append on master: `begin; Integer(z); k = +"n"; rescue; n = 1; end; k << x`, where `z` does not parse.

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

`dyn_lit_lost` reads the body's statements in order and answers the parameters appended to through such a local: it holds the parameter from `t = k` until a statement gives it another value on every path that goes on past it. That is a write (`t = t.dup`, `t += x`, `t &&= v`, `t, *j = v, w`, `(t, j), l = [v, 1], 2`, `t, j = f(x)` where the call reads neither name, `j = t = v`), also where it is an Array literal's element, a call's receiver or argument, or an interpolation's part, which always run; an `if`, an `unless`, a `case` or a `case/in` whose every arm, an else among them, has one or leaves the block with `next`, `break`, `return` or `raise` (a `case/in` needs no else: a miss raises); a `begin` whose ensure has one, or whose body has one and every rescue has one or leaves; and `(t = v) << x`, whose write runs first. The answer travels beside the append bit (`DynReach.lost`) and is asked where a String variable is already refused or shared: `f.call(s)`, `f.(s)`, `f[s]`, a yield into `&f`, and a call with a literal block to a method that yields its parameter. The call is refused in the route's own sentence. The same call site refuses a String variable in an Array literal the method yields with a splat (`def y(a) = yield(*a)`; `y([s]) { |k| k << "x" }`), a copy for a plain append too.

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

470 more for the paths the walk reads and the ones it does not (two holders, five call forms, 47 block bodies: an arm or a rescue that leaves beside one that writes, a multiple assignment with a rest, a nested or a single target, a write inside an expression, the forms of the first paragraph, and twins in which a path keeps the caller's String):

| on master | with this | programs |
|---|---|---|
| wrong | refused | 46 |
| right | refused | 32 |
| right | right, master's C byte for byte | 304 |
| refused | refused | 54 |
| wrong, no build or a crash | the same, master's C | 34 |

Under `--share-strings` nothing changes: the same 2,256 give master's answer and master's C (`refuse_lost_append` stands down there; what the local holds is the rule's to say). The five reject tests are in `test/share/reject.list` with CRuby's answers.

**Not in this change.** Of the 442, 343 are wrong on both (35 only in the text of an error). Still a silent copy: an Array element as the argument, a String that reaches the local through a conditional value, a second local or a call (`t = c ? d : k`, `u = t`, `t = k.itself`), an arm that takes the String back (`o = k; if c then k = +"p" else k = o end`), an Array variable splatted into the yield, the iterators (`each`, `then`, `tap`), a block forwarded with `&` through a second method (`def fwd(s, &b) = run(s, &b)`), a parameter written in a nested block that does not run (`[].each { k = +"n" }; k << x`), an instance variable handed to the method that yields (`run(@s) { |k| k ||= d; k << x }`, 24 of the 34 of the third set), and an append ahead of the write inside an arm of an `if` whose every arm writes (`if c then k << x; k = +"p" else k = +"q" end`).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
