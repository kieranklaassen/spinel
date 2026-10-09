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

Cost: such a call now passes a nil test, and a call master ran right, on a receiver that is not nil, pays for it. A million calls, gcc and clang, instructions a call: an own String method on a local, `s&.tag(i)`, 50,662,912 to 52,662,961 and 50,624,429 to 52,624,427 (2 and 2); answering a String 4 and 2; on an instance variable 0 and 2; beside an argument made in place, `s&.tag([i])`, 4 and 2; an own Integer method 0 and 5 (clang had folded the unguarded loop away); an own Float method 0 and 2. A receiver that is itself a call is held in a root while an argument is made, `mk&.tag([i])`: 13 and 21, of 380 and 390; with a plain argument, `mk&.tag(i)`, the call takes 1 and 2 instructions fewer than on master (62,662,967 to 61,662,917 and 63,624,437 to 61,624,437). Master's own `s&.index("c", i & 1)` against `s.index("c", i & 1)` is 12 and 14. Compile time: 1,000 such calls in one function take Spinel 2.9% longer (1,506,454,706 to 1,550,106,792 instructions) and 2,000 take 2.4% longer (3,685,747,024 to 3,773,832,530), and the C compiler about what the guard written by hand takes it on master (`s ? s.tag(i) : nil`): with 2,000 calls gcc 7 s to 10 s (by hand 10 s), clang 4 s to 14 s (by hand 12 s); with 250 calls 1.5 s to 1.6 s and 1.0 s to 1.2 s (by hand 1.7 s and 1.3 s). No other call's C changes.

`emit_call_body` takes a call of a method the program added to a builtin class ahead of every builtin arm. That site never looked at the operator, so for a String, an Integer or a Float, which hold nil in their own C type, it took the call before the nil guard (`emit_call_safe_nav_arms`) saw it. A Symbol, a Range, a Time or a Class that may be nil is a boxed value, and was answered right.

The site now writes the guard where the call stands, as one expression: the receiver into a temp, the nil test, and in the arm that is not nil what the call hoists (its arguments' temps) and then the call the site made before. Nothing leaves the call's place, so what the statement runs ahead of the call still runs ahead of it, and an argument runs only for a receiver that is not nil. It is the form master writes for a boxed receiver's `&.` (`({ sp_RbVal _sn_1 = ...; _sn_1.tag == SP_TAG_NIL ? sp_box_nil() : ...; })`), with an `if` in place of the `?:` so that the hoisted statements stand inside the arm. `emit_call_body` keeps its line count.

A String held in a temp is the String as it was, and the call read it after its arguments: `s&.pair(add(s))`, where `add` appends to `s` and answers an Array, passes the longer one, on master too, as CRuby's one object shows it. So a String that is a read (a local, an instance variable, a global, a field) is tested where it stands and read again by the call, as it was. Any other String receiver runs once, into a temp, and is guarded only where no argument and no default the call leaves out can run the program's code (anything but reads, literals and what is made of them; a name the program gave the builtin, `[]` on an Array, an operator on an operand that is no Integer or Float, `5 == o`, and the hash of a key that is no String, Symbol or Integer are such code); beside one that can, the call keeps the C it had. A read that makes such a call (`ys[0]` against the program's `Array#[]`) is not read again: it runs once, into the temp. A call of a method that keeps self as a handle under `--share-strings` (`r.name&.add!("d")` where `add!` appends to self) takes the receiver's handle, which the temp is not: it is guarded only where the receiver is a read the call reads again, and otherwise keeps the C it had; master answers it right under the flag and still does. The temp is rooted unless nothing can run between it and the call: the call hoists nothing and each parameter is given a pure read of its own type.

The value is boxed by the type read for the call, so the guard is written only where that type is the method's own. A redefined `Float#eql?` that answers a Symbol is read as a boolean with or without the `&.` (`v.eql?(2.5)` prints `true`; with `&.` the C does not build; both on master and here): such a call keeps the C it had, and so does a receiver that is boxed (one narrowed by a `case` or an `and`).

Leaving the call to reach the guard on its own would not do: the numeric arms between this site and the guard answer a name the program redefined (`v&.numerator`, `v&.<=>(o)`) with the builtin.

Not in this change, each on master and here: a String receiver that is itself a call, beside an argument or a left-out default that can run the program's code, still runs its method on the nil (`fresh(9)&.pair([4].inspect)` prints `"-[4]"`, and the chain `v&.idem&.pair(tick(1))` prints `"-1"`); a receiver that an argument assigns is read after the assignment, where the call always read it (`@v&.pair(reset)`, where `reset` assigns `@v`, passes the new String, and `s&.pair((s = nil; 1))` prints `"-1"`); a method the program names `lazy` still runs on the nil (`v&.lazy`); a method added to IO still runs on the nil, and one added to File raises NoMethodError for it; a method added to Array or Hash answers nil already, but two arguments still run ahead of the guard (`def pair(a, b)`, `v&.pair(tick(1), tick(2))` prints both ticks); an own method that answers nil, as the first of two arguments, runs after the second (`two(s&.info(1), side)` prints `side` first, as `two(info(1), side)` does for a plain `def info`); and a constant assigned such a call does not build (`X = s&.info(1)`, with or without the `&.`).

`test/safe_nav_reopened_builtin.rb` prints 46 lines and carries `# spinel: gc-stress`; master prints `"-1"`, `"-2"`, `"-3"` and `"own "` for the four nils and then raises on `nil&.succ`. `test/share/safe_nav_reopened_builtin_handle.rb` (7 lines, run by `make share-strings-test`) holds the handle calls; master passes it.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this head, in a container without CRuby 4.0: the build; `test/safe_nav_reopened_builtin.rb` with gcc and clang at `SPINEL_GC_STRESS` 0, 1 and 2 and with `--share-strings`; `test/share/safe_nav_reopened_builtin_handle.rb` under `--share-strings` with gcc and clang at stress 0, 1 and 2; `ruby tools/gate.rb check`; `make cident` against its base, master 9c57b440b (6,655 programs identical, 1 differs: the new test); `make share-strings-test` and `make int-min-test`; the test's `.expected` is CRuby 3.3.6's, run with `--enable-frozen-string-literal`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (the test has none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not: the C is master's byte for byte)
- [ ] Depends on: none
