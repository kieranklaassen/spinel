<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A matcher object held boxed was never asked its `===` by a `when`.

```ruby
class Above
  attr_accessor :n
  def initialize(n) = @n = n
  def ===(o) = o > @n
end
[Above.new(1), Above.new(5)].each do |pat|
  case 3
  when pat then puts "above #{pat.n}"
  end
end
```

Master (a3941433) prints nothing. CRuby prints `above 1`. Written as a call, `puts "above #{pat.n}" if pat === 3`, master prints `above 1`.

An Array of objects holds them boxed, so does a Hash value, and the block parameter over them. `when pat` on a boxed arm calls a Proc and otherwise goes to the runtime, which knows the builtin patterns and equality but not a class the program wrote. `===` now joins the operators `sp_user_binop_dispatch` carries, as `==` and `[]` did, and in a program that has a class with its own `===` the boxed `when` test ends in `sp_poly_when_eq` (new in `lib/spinel_rt.h`), which asks that table before `sp_poly_case_eq` and holds the pattern and the subject across the call. An operand the method's parameter cannot take keeps `sp_poly_case_eq`'s answer.

Cost: a program with a class that defines `===` gains that arm in its operator table (81 programs of the corpus, 76 of them through Set's own `===`, three lines each; all 81 answer as before at `SPINEL_GC_STRESS` 0, 1 and 2); a boxed `when` in such a program makes one more call. A program with no such class keeps its C.

This sits on the pull request "A `when` arm held boxed is asked ===, not ==": both change the last call of `emit_when_boxed_test`.

Not in this change: `when *list` with a matcher object in the list.

Test: `test/case_when_boxed_user_case_eq.rb`, 11 lines; 8 of them fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
