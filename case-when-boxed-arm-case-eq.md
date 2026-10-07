<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A `when` arm held boxed was compared with `==` and never asked `===`.

```ruby
[(1..3), Integer, 2].each do |pat|
  case 2
  when pat then puts "hit"
  else puts "miss"
  end
end
```

Master (a3941433) prints `miss`, `miss`, `hit`. CRuby prints `hit` three times. Written as a call, `p(pat === 2)`, master prints `true` three times.

A block parameter over an Array of several kinds, an element of such an Array, a Hash value and a parameter given several kinds are held boxed. `emit_when_boxed_test` called a boxed Proc and compared every other arm with `sp_poly_eq`, so a Range or a Class held that way never matched, and a Range or a Class subject matched itself (`(1..3) === (1..3)` and `Integer === Integer` are false). It now ends in `sp_poly_case_eq`, the function the call `pat === v` on a boxed receiver ends in: a Class its instances, a Range its cover, a Regexp its match against a String, else equality with the same object first. That is one token; no arm that matched by equality stops matching.

Cost: `sp_poly_case_eq` in place of `sp_poly_eq`, a few tag tests before the same equality. One program of the corpus changes its C, `test/proc_pattern_from_container.rb`, and passes as before.

Not in this change: a Regexp held boxed matches as `pat === str` does on a boxed receiver, which does not set `$~`; an object of a class with its own `===` is the next pull request.

Test: `test/case_when_boxed_pattern.rb`, 16 lines; 13 of them fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
