<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def band(v)
  case v
  when "a".."m" then "low"
  when "n".."z" then "high"
  when 1..9 then "digit"
  else "other"
  end
end
puts band("c"), band("q"), band(5), band(nil)
```

prints `other`, `other`, `digit`, `other`. CRuby prints `low`, `high`, `digit`, `other`. `("aa".."az") === h["k"]` for a boxed `"ab"` and `["c", 5, "q", nil].select { |e| ("a".."m") === e }` answer `false` and `[]` the same way.

`===` of a String Range is membership. With a boxed value it was written as an equality of the Range and the value, which no String satisfies, in two places, one commit each:

- the `===` call. The arm for a receiver that compares by value leaves out an Integer Range and a Float Range by their families 5 and 6 of `eq_family`, and not the String Range's 7. It leaves 7 out too, and `emit_range_call` answers.
- `when`. `emit_when_typed_test` had an arm for a String subject against a String Range, and for a boxed subject against an Integer or a Float Range, and none for a boxed subject against a String Range. It gains one.

Both answer alike. A value that holds a String is covered by its bytes and length, the plain String and the appended one (a shared handle). Every other value is asked what master asked it, the same `sp_poly_eq` with the boxed Range in the same operand order, so no answer changes for a value that holds no String. One test on the value's tag tells the two apart.

Master's C stays, for the whole program, where the pull request beneath keeps `cover?` of the Range as it is: in a program that has, or may have, a `===`, a `<=>`, an `==` or a `succ` of its own, in any class, and in one where that pull request does not say what a box tagged as a handle holds (it stores the String of a method call its scan does not follow). "May have" is its answer: a `def` in the builtin's class, a `def` or a Symbol of the name anywhere in the program, or a site where a method is named, made, mixed in or loaded by something the text does not spell. That takes in a program that mixes in a module, its own too, and one that requires set, csv, uri, bigdecimal, pathname, stringio, json or strscan, or uses `Gem::Version`.

Master's C stays as well at a `===` the compiler's own Ruby asks (`enum_builtin_node`). `grep` and `grep_v` ask it of each element there, so they answer as on master, also for a program that gives Array a `grep` or an `each` of its own, which CRuby's `grep` would call and the builtin does not.

Cost, in instructions a turn against the pull request beneath, gcc 13.3 / clang 18.1, callgrind over 300,000 turns of `n += 1 if r === x`, and of a `case x` with the one arm `when "aa".."az"`, `x` read once from `["zz", 1]` (the String) or `["ab", 1]` (the Integer):

| x | `===` | `when` |
|---|---|---|
| the String `"zz"`, outside the Range | -86 / -87 | -79 / -85 |
| an Integer | +12 / +3 | +6 / +2 |
| an Integer that takes a `when 1` ahead of the arm, two cases a turn | | +1 / 0 |

The Integer row is a cost on a program master answered right: the test that tells a String from every other value now runs ahead of the equality master wrote. It is one mask test on the tag; written as two tests it measured +8 / +8 and +8 / +6, dearer in three of the four cells and cheaper by 4 for `===` with gcc. The String row is fewer because the Range is no longer boxed for a String. The last row's arm is not reached and adds nothing to that path: it is the C compiler's layout, and the same turn measures 0 / +2 where the `case` runs in a block and +2 / 0 with the Range in a local.

`make cident` against the commit beneath: the C of eight programs differs, each one of the seventeen tests, and of 6,901 it is identical; with `--share-strings` the same eight differ and both builds refuse one, named in test/share/known-failures.txt. optcarrot's C is unchanged.

Not here: a boxed String Range equal to the Range is answered as on master's plain run, `true`, and takes the arm, where CRuby says `false` unless the program gives Range a `to_str` or a `method_missing`; that is not cured. At `SPINEL_GC_STRESS=2` master's answer for `===` there was another, `false`, because it did not hold the value the argument had just made. `grep` and `grep_v` with a String Range, on any receiver, still find no boxed String, and a `===` or a `when` in a method the program itself names `__enum_...` keeps master's answer, since such a name reads as the compiler's own Ruby. A String that master holds otherwise than CRuby by a limit it documents is compared as master holds it, also where master's `false` for a boxed String happened to be CRuby's answer: in the default build the Range answers by its copies of its two ends where the program changes in place the String an end was made from (docs/limitations.md, "A String Range keeps copies of its endpoints"); under `--share-strings` master keeps those Strings and the value is compared with them as they are, as CRuby does; and a String the program transcoded out of UTF-8 is compared by the UTF-8 bytes master keeps for it ("Mixed / non-UTF-8 encodings"). A method the program gave a builtin class and master answers by the builtin (its own `select`, `map` or `each` of Array, its own `<<` of String) is still answered by the builtin, so a `===` or a `when` with a Range it would not have made, with a String it would not have built, or in a block it would not have run is now `true` where it was `false`: that method is not changed here. As before this change: `K === x` for a constant `K` that holds a String Range answers false (the call is read as a class test); `all?`, `any?` and `none?` of a String Array with a String Range answer as if no element matched; `in "a".."m"` is not touched.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here before that, on these two commits over master `40b81c3585b7` with the pull request they depend on beneath them (Linux x86-64, gcc 13.3 and clang 18.1, CRuby 3.3.6; CRuby 4.0 is not installed here, so the first box below is open for the gate): the build from nothing, the seventeen tests at five collector settings with both compilers, with and without `--share-strings`, `ruby tools/gate.rb check-range HEAD^1 HEAD` on each commit, `make gc-stress-test`, `make share-strings-test`, `make int-min-test`, `make cident` against the commit beneath and the figures above. The seventeen tests were also run at `SPINEL_GC_STRESS=2` with `SPINEL_GC_VERIFY` 0 and 1, and under `--int-overflow=wrap` and `--int-overflow=promote`. `make share-verify-test` ends as it does on master without these commits: one failure (test/share/share_strings_net_http_zlib.rb) and two new diagnostics (test/share/share_strings_exception_dispatch.rb).

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: "A String Range's cover? and include? read a boxed appended String" (its answer for the program, whether a box tagged as a handle holds one, its question whether the membership is the builtin's and its out-of-line read of the handle are used here)
