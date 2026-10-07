<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

The statement form of `when *list` did not ask the list what the value form asks it.

Cost: a statement `when *list` whose list holds several kinds now pays what the case value pays. A test of a list of three with an Integer subject runs 815.3 instructions under callgrind where the `==` search ran 240.7 (the case value: 819.3 on the pull request beneath, 789.2 on master). A list of the subject's own kind keeps the typed search, master's C: 38.5 on both. No program of the corpus changes its C.

```ruby
list = [1..3, String, :q]
case 2
when *list then puts "in"
else puts "out"
end
puts(case 2 when *list then "in" else "out" end)
case 2.5
when *[1, 2] then puts "in"
else puts "out"
end
```

Master (a2bd8900) prints `out`, `in`, `in`. CRuby prints `in`, `in`, `out`.

`emit_case` chose the search by the list alone: an Integer, String or Float Array took the `include` of its own kind whatever the subject, so a Float subject was truncated into an Integer list and a String subject beside an Integer list did not build; a list of several kinds was compared with `==`, after evaluating the subject a second time; any other list was no match. It now keeps the typed search where the list is of the subject's own kind (an Integer subject in an Integer or Float Array, a String in a String Array, a Float in a Float Array) and sends every other list to `sp_case_splat_match`, as `emit_case_expr` does. One operand stays as it was, no match: an object of the program (a Struct, an Enumerable), which the case value does not spread yet.

This sits on the pull requests "A `when *x` spreads what x holds before it is searched" and "A Class, a Range or a Regexp in `when *list` is asked === alone": the statement now reaches the helper those two repair, and without them it would take over the value form's wrong answers for a Class, a Range or a Regexp subject and for a plain value.

Not in this change: an object with its own `===` inside a list is not asked, and a lambda inside a list is not called.

Test: `test/case_when_splat_statement.rb`, 16 lines. Three of its arms do not build on master; of the 13 lines that do, 6 fail.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
