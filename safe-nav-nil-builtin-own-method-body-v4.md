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

Cost: such a call now passes a nil test, and a call master ran right, on a receiver that is not nil, pays for it. A million calls, gcc and clang, instructions a call: an own String method on a local, `s&.tag(i)`, 50,661,994 to 52,661,994 and 50,623,372 to 52,623,370 (2 and 2); answering a String 4 and 2; on an instance variable 0 and 2; beside an argument made in place, `s&.tag([i])`, 4 and 1; an own Integer method 0 and 5 (clang had folded the unguarded loop away); an own Float method 0 and 2. A receiver that is itself a call is held in a root while an argument is made, `mk&.tag([i])`: 13 and 21, of 380 and 390; with a plain argument, `mk&.tag(i)`, it is 1 and 2 cheaper. Master's own `s&.index("c", i & 1)` against `s.index("c", i & 1)` is 12 and 14. Compile time: 2,000 such calls in one function take Spinel 2.3% longer (3,682,747,044 to 3,767,348,441 instructions) and the C compiler about what the guard written by hand takes it on master (`s ? s.tag(i) : nil`): gcc 8 s to 11 s (by hand 11 s), clang 4 s to 14 s (by hand 13 s); with 250 calls 1.4 s to 1.6 s and 1.1 s to 1.3 s. No other call's C changes.

`emit_call_body` takes a call of a method the program added to a builtin class ahead of every builtin arm. That site never looked at the operator, so for a String, an Integer or a Float, which hold nil in their own C type, it took the call before the nil guard (`emit_call_safe_nav_arms`) saw it. A Symbol, a Range, a Time or a Class that may be nil is a boxed value, and was answered right.

The site now writes the guard where the call stands, as one expression: the receiver into a temp, the nil test, and in the arm that is not nil what the call hoists (its arguments' temps) and then the call the site made before. Nothing leaves the call's place, so what the statement runs ahead of the call still runs ahead of it, and an argument runs only for a receiver that is not nil. It is the form master writes for a boxed receiver's `&.` (`({ sp_RbVal _sn_1 = ...; _sn_1.tag == SP_TAG_NIL ? sp_box_nil() : ...; })`), with an `if` in place of the `?:` so that the hoisted statements stand inside the arm. `emit_call_body` keeps its line count.

A String receiver is rooted in its temp only where something can run between the temp and the call and may leave the temp the only holder: not where the call hoists nothing and each argument is a plain read of its parameter's type, and not for a local or an instance variable that no argument or default can assign (`read_rebound_by`).

The value is boxed by the type read for the call, so the guard is written only where that type is the method's own. A redefined `Float#eql?` that answers a Symbol is read as a boolean with or without the `&.` (`v.eql?(2.5)` prints `true`; with `&.` the C does not build; both on master and here): such a call keeps the C it had, and so does a receiver that is boxed (one narrowed by a `case` or an `and`).

With a chain for a receiver (`v&.idem&.pair(tick(1))`) gcc's build ran the argument ahead of the receiver's call; the receiver is in its temp first.

Leaving the call to reach the guard on its own would not do: the numeric arms between this site and the guard answer a name the program redefined (`v&.numerator`, `v&.<=>(o)`) with the builtin.

Not in this change, each on master and here: a method the program names `lazy` still runs on the nil (`v&.lazy`); a method added to IO still runs on the nil, and one added to File raises NoMethodError for it; a method added to Array or Hash answers nil already, but two arguments still run ahead of the guard (`def pair(a, b)`, `v&.pair(tick(1), tick(2))` prints both ticks); an own method that answers nil, as the first of two arguments, runs after the second (`two(s&.info(1), side)` prints `side` first, as `two(info(1), side)` does for a plain `def info`); and a constant assigned such a call does not build (`X = s&.info(1)`, with or without the `&.`).

`test/safe_nav_reopened_builtin.rb` prints 40 lines and joins `GC_STRESS_TESTS`; master prints `"-1"`, `"-2"`, `"-3"` and `"own "` for the four nils and then raises on `nil&.succ`.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this head, in a container without CRuby 4.0: the build; `test/safe_nav_reopened_builtin.rb` with gcc and clang at `SPINEL_GC_STRESS` 0, 1 and 2 and with `--share-strings`; `ruby tools/gate.rb check`; `make cident` against master (6,512 programs identical, 1 differs: the new test); `make share-strings-test` and `make int-min-test`; the test's `.expected` is CRuby 3.3.6's, run with `--enable-frozen-string-literal`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (the test has none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not: the C is master's byte for byte)
- [ ] Depends on: none
