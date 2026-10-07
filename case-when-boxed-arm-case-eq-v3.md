<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A `when` arm held boxed was compared with `==` and never asked `===`.

Cost: a boxed `when` test now tells an object or a Class arm from the rest before it compares. A million `when pat` tests under callgrind, instructions a test, master then here: an Integer arm beside an Integer subject 22, 25 where it matches and 18, 20 where it does not; an Integer arm beside a subject that is no Integer 123, 135 (a Symbol, a String, nil) and 133, 146 (a Float); a Symbol arm beside a Symbol 132, 146; a String arm beside a String 227, 241; a Range arm, which never matched, 134, 115. The arm's kind is known only when the case runs, so the test cannot be decided by the compiler. In the corpus the generated C changes for the new test and for `test/proc_pattern_from_container.rb`, which answers as before.

```ruby
[(1..3), Integer, 2].each do |pat|
  case 2
  when pat then puts "hit"
  else puts "miss"
  end
end
```

Master (8dc55225) prints `miss`, `miss`, `hit`. CRuby prints `hit` three times. Written as a call, `p(pat === 2)`, master prints `true` three times.

A block parameter over an Array of several kinds, an element of such an Array, a Hash value and a parameter given several kinds are held boxed. `emit_when_boxed_test` called a boxed Proc and compared every other arm with `sp_poly_eq`, so a Range or a Class held that way never matched, and a Range or a Class subject matched itself (`(1..3) === (1..3)` and `Integer === Integer` are false). It now ends in `sp_poly_when_eq` (new, inline, in `lib/spinel_rt.h`). An arm that is an object or a Class goes to `sp_poly_case_eq`, the function the call `pat === v` on a boxed receiver ends in: a Class its instances, a Range its cover, a Regexp its match against a String, else equality with the same object first. An arm that is a number, a String, a Symbol, nil or a boolean keeps `sp_poly_eq`, the call it had, which is what `sp_poly_case_eq` answers for it after its own tests. No arm that matched by equality stops matching.

Not in this change, each as `pat === v` answers on a boxed receiver today, since no line of `sp_poly_case_eq` is touched: a Regexp held boxed does not set `$~`; a Regexp arm beside a Symbol subject is no match; an object of a class with its own `===` is the next pull request.

Test: `test/case_when_boxed_pattern.rb`, 16 lines; 13 of them fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
