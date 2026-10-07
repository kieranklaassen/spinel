<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A matcher object held boxed was never asked its `===` by a `when`.

Cost, only in a program that has a class with its own `===` (every program that requires Set is one): a boxed `when` test whose arm is no such object pays one more tag test, 21.7 instructions a loop iteration for an Integer arm where the pull request this sits on gives 17.7 and master 14.7; an arm that is such an object is asked, 172.7 instructions where the comparison that never matched took 129.7, and a Set arm 500.7 where 220.7 (`Set#===` is `include?`). A file of 4,000 boxed arms and 200 classes compiles with 1.8% more instructions where no class has `===` and 0.13% more where the first has. A program with no such class keeps its C.

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

Master (a2bd8900) prints nothing. CRuby prints `above 1`. Written as a call, `puts "above #{pat.n}" if pat === 3`, master prints `above 1`.

An Array of objects holds them boxed, so does a Hash value, and the block parameter over them. `when pat` on a boxed arm calls a Proc and otherwise goes to the runtime, which knows the builtin patterns and equality but not a class the program wrote. `===` now joins the operators `sp_user_binop_dispatch` carries, as `==` and `[]` did, and in a program that has a class with its own `===` the boxed `when` test ends in `sp_poly_when_user_eq` (new, inline, in `lib/spinel_rt.h`): an arm that is an object of the program is asked through that table, out of line in `sp_poly_when_obj_eq`, which holds the pattern and the subject across the call; any other arm is answered as before. An operand the method's parameter cannot take keeps `sp_poly_case_eq`'s answer.

A `===` that changes its parameter in place (`o << "!"`, itself or through a method it hands the parameter to) gets no arm in the table and the `when` answers as it did: the table has no String slot to lend it, and no call has widened the subject for the append. `comp_param_changed_in_place` (new, `src/analyze.c`) asks the body what the by-reference parameters are found with. The pull request "A case subject is an argument of its object arm's ===" adds the same function in the same lines: whichever lands second drops the hunk.

One line that was right by accident now raises. A `===` whose parameter a written call has typed (`p(k === :upcase)` types `o` a Symbol) and whose body master cannot run for that type (`o.equal?(self)`: a Symbol receiver's `equal?` beside an object raises NoMethodError on master, a fault of its own) was never reached by the `when`, which answered no match, as CRuby does; asked now, it raises that NoMethodError. The call written out, on the line above in the same program, raises it on master too: the `when` reaches the fault, it does not make it. The fix for that `equal?` is small and separate; with it beneath this one the line is right again.

The generated C changes for 82 programs of the corpus, each with a class that has its own `===` (the Set package's among them); all answer as before.

This sits on the pull request "A `when` arm held boxed is asked ===, not ==": both change the last call of `emit_when_boxed_test`.

Not in this change: `when *list` with a matcher object in the list; a Method object held as the arm is not called.

Test: `test/case_when_boxed_user_case_eq.rb`, 17 lines; 8 of them fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
