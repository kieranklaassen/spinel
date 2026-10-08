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

prints `other`, `other`, `digit`, `other` (`spinel diff`: output-diff). CRuby prints `low`, `high`, `digit`, `other`. `("aa".."az") === h["k"]` for a boxed `"ab"` and `["c", 5, "q", nil].grep("a".."m")` answer `false` and `[]` the same way.

`===` of a String Range is membership. With a boxed value it was written as an equality of the Range and the value, which no String satisfies, in two places, one commit each:

- the `===` call. The arm for a receiver that compares by value leaves out an Integer Range and a Float Range by their families 5 and 6 of `eq_family`, and not the String Range's 7. It leaves 7 out too, and `emit_range_call` answers: a String is covered by its bytes and length, the plain one and the appended one (a shared handle) alike.
- `when`. `emit_when_typed_test` had an arm for a String subject against a String Range, and for a boxed subject against an Integer or a Float Range, and none for a boxed subject against a String Range. It gains one: a plain String is compared where the arm is written, a boxed object is asked out of line (`sp_srange_when_obj`).

What does not change: a value that holds no String is not covered, and that includes an object with a `<=>` of its own, which CRuby asks and `===` here does not, before or after; an object of one of the program's classes as the subject of `when` is still asked whether it equals the Range; a program with a `Range#===` of its own, or its own `String#<=>`, `#==` or `#succ`, keeps master's C, and so does one whose box may hold a plain String under the handle's tag (the piece beneath says which). One answer changes beside the String's: a boxed String Range equal to the Range was `true` and took the arm, and is `false`, as in CRuby.

Cost on a program master answered right: one instruction a turn with gcc in the last row, none elsewhere. In instructions a turn against the commit beneath, gcc 13.3 / clang 18.1, callgrind over 300,000 turns of `n += 1 if r === x`, and of a `case x` with the one arm `when "aa".."az"`, `x` read once from `["ab", 1]`:

| x | `===` | `when` |
|---|---|---|
| an Integer | -238 / -207 | -228 / -206 |
| a String outside the Range | -63 / -55 | -51 / -49 |
| an Integer that takes a `when 1` ahead of the arm, two cases a turn | | -4 / 0 |
| the same in a program that holds an appended String | | +1 / 0 |

The Range is made only when the arm is reached, and it is not boxed. The arm adds nothing to the path of a `when` taken ahead of it; the last two rows are gcc keeping the subject in other registers there. No corpus program's C changes beyond the tests. optcarrot's C is unchanged.

Not here: `K === x` for a constant `K` that holds a String Range answers false (the call is read as a class test); `all?`, `any?` and `none?` of a String Array with a String Range answer as if no element matched; `in "a".."m"` is not touched.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: "A String Range's cover? and include? read a boxed appended String" (its answer for the program, whether a box tagged as a handle holds one, and its out-of-line read of the handle are used here), and through it "The two ends of a String Range made on the spot are both kept, and made in order" and "A String Range that no name holds is kept until it is read"
