<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class String
  def pair(a) = "#{self}-#{a}"
end
s = ARGV.size > 0 ? "s" : nil
p s&.pair(1)
```

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-nil
+"-1"
```

The method ran on the nil, and an argument with an effect ran too. The same for a method added to Integer or Float, and for a builtin's name the program redefines on one of the three (`s&.upcase` against the program's `def upcase`).

Cost: such a call now passes the nil guard every other `&.` call passes, which on a String holds the receiver in a rooted temp. A million calls of an own String method on a receiver that is not nil count 52,661,998 instructions on master and 70,662,000 here with gcc (18 a call), 52,623,370 and 67,623,372 with clang (15); where the method answers a String, 19 and 21 a call. Master's own `s&.index("c", i)` against `s.index("c", i)` is 12 and 14 a call. An own Integer method: 0 with gcc, and 7 with clang, which had folded the unguarded loop away; an own Float method: 0 and 3. No other call's C changes.

Depends on "A &. to a method that answers nil builds wherever its value is read": without it an own method that answers nil, called through `&.` with an argument made in place and read beside a later operand (`p i&.note([1, 2]), j&.note([1, 2])`, the test's last line), is right on master for a receiver that is not nil and does not build here.

`emit_call_body` takes a call of a method the program added to a builtin class ahead of every builtin arm. That site never looked at the operator, so for a String, an Integer or a Float, which hold nil in their own C type, it took the call before the nil guard (`emit_call_safe_nav_arms`) saw it. A Symbol, a Range, a Time or a Class that may be nil is a boxed value, and was answered right. Where the site is about to take the call and the guard is pending (`sn_guard_pending`), it now calls the guard itself: the guard re-enters with the receiver in its temp, and the site takes the call then. The call is the one the site made before; only the nil test stands around it, and `emit_call_body` keeps its line count.

The guard boxes the value by the type read for the call, so the site asks it only where that type is the method's own. A redefined `Float#eql?` that answers a Symbol is read as a boolean with or without the `&.` (`v.eql?(2.5)` prints `true`; with `&.` the C does not build; both on master and here): such a call keeps the C it had.

With a chain for a receiver (`v&.idem&.pair(tick)`) gcc's build ran the argument ahead of the receiver's call; the guard holds the receiver in its temp first.

Leaving the call to reach the guard on its own would not do: the numeric arms between this site and the guard answer a name the program redefined (`v&.numerator`, `v&.<=>(o)`) with the builtin.

"v&.fdiv(2) and the other Ruby-defined Integer methods keep the &." left such a call on its typed emitter; for a method the program defines, that emitter is this site, so an Integer was still wrong.

Not in this change, each on master and here: a method the program names `lazy` still runs on the nil (`v&.lazy`); a method added to IO still runs on the nil, and one added to File raises NoMethodError for it; a method added to Array or Hash answers nil already, but two arguments still run ahead of the guard (`def pair(a, b)`, `v&.pair(tick(1), tick(2))` prints both ticks).

`test/safe_nav_reopened_builtin.rb` prints 30 lines; master prints `"-1"`, `"-2"`, `"-3"` and `"own "` for the four nils and then raises on `nil&.succ`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
