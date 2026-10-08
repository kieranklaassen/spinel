<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A `when` arm held boxed was compared with `==` and never asked `===`.

Cost: the arm's kind is known only when the case runs, so a boxed `when` test now reads the arm's tag before it compares. A million tests under callgrind, instructions a test more than master (a loop round is 18 to 248 on master):

| arm, subject | gcc | clang |
|---|---|---|
| an Integer beside an Integer (typed or boxed) | 1 to 2 fewer | 0 to 3 |
| an Integer beside a Symbol, a String, nil, a Float | 10 to 11 | 3 |
| a Symbol, a String or nil beside its own kind, a Float beside an Integer, boxed | 13 to 14 | 0 |
| a Symbol or a String beside a subject typed so | 14 | 0 to 3 |
| `true` beside a subject typed a boolean | 14 | 75 |
| two boxed arms in one `when` | 21 | 4 |

In a program that compares two boxed values anywhere else (`p(a == b)`, `p(pat === 3)`) the same loops cost 3 to 5 with gcc and 0 to 4 with clang, the boolean row 5 and 2: the larger figures are how each compiler lays out `sp_poly_eq_slow` when one loop is its only caller. The corpus C changes for the new test and for `test/proc_pattern_from_container.rb`, which answers as before.

```ruby
[(1..3), Integer, 2].each do |pat|
  case 2
  when pat then puts "hit"
  else puts "miss"
  end
end
```

Master (42557a3c) prints `miss`, `miss`, `hit`. CRuby prints `hit` three times. Written as a call, `p(pat === 2)`, master prints `true` three times.

A block parameter over an Array of several kinds, an element of such an Array, a Hash value and a parameter given several kinds are held boxed. `emit_when_boxed_test` called a boxed Proc and compared every other arm with `sp_poly_eq`, so a Range or a Class held that way never matched, and a Range or a Class subject matched itself (`(1..3) === (1..3)` and `Integer === Integer` are false).

The test already read the arm's tag to find a Proc. It now decides on that tag once: two Integers compare in line, as `sp_poly_eq` compares them, and only where the subject's type allows an Integer; an object that is no Proc and a Class go to `sp_poly_case_eq`, the function the call `pat === v` on a boxed receiver ends in (a Class its instances, a Range its cover, a Regexp its match against a String, else equality with the same object first); a number, a String, a Symbol, nil or a boolean goes to `sp_poly_eq_slow`, the equality it had. No arm that matched by equality stops matching. No runtime function is added.

Not here, each as `pat === v` answers on a boxed receiver today, since no line of `sp_poly_case_eq` is touched: a Regexp held boxed does not set `$~`; a Regexp arm beside a Symbol subject is no match; a number beside an object whose own `==` answers for numbers is no match (CRuby's `3 === obj` asks `obj == 3`); an object of a class with its own `===` is a pull request of its own.

Test: `test/case_when_boxed_pattern.rb`, 16 lines; 13 of them fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
