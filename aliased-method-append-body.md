<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A method that appends to its String parameter is lent the caller's slot, so the append reaches the caller. Once an alias uses the method's name it is not (the alias's call sites keep the plain ABI, `compute_byref_out_params`), the call hands it a copy, and the append is lost with no word:

```ruby
class Html
  def render(out)
    out << "<p>"
    out << "hi"
    out << "</p>"
  end
  alias to_html render
end
buf = +""
Html.new.render(buf)
p buf        # CRuby "<p>hi</p>", spinel ""
```

Without the alias line the same program prints `"<p>hi</p>"`. The call is now refused, by either name, in the call route's own sentence (`refuse_string_copy_to`). The message names the rewrite that is shared today, a method written in place of the alias that calls the other: `def to_html(out) = render(out)`.

**The cost: right programs are refused.** 9,028 programs (14 ways to write the method and the alias, 18 bodies, 18 kinds of argument, either name, five ways to read the variable, 12 call forms): 4,446 have master's C, 114 are refused on both, 4,468 are newly refused. Of the 4,468, 2,091 are silently wrong on master and 2,377 are right:

| right on master, refused here | programs |
|---|---|
| the variable is read before the call and never after | 980 |
| nothing reads it at all: a parameter, a block parameter, a local used in a block, a class variable, a local with a second name nobody reads, an instance variable whose reader or subclass method is never called | 732 |
| the mutation changes nothing for the value at hand (`v << x if v.size > 99`, a `gsub!` with no match) and the variable is read after | 521 |
| only its size is read after, and the mutation keeps the size (`upcase!`, `v[0] = "!"`) | 144 |

The rule does not follow the value, the order of the reads, or whether a method that reads is ever called; the settled alias and read routes do not either. In the first two rows nothing reads the String after the append.

Left to build with master's C: a local, an instance variable or a global that nothing else reads (an instance variable is asked for by name in every class, since a subclass reads the same slot), a local that only holds a frozen literal, a parameter the method assigns before the append, an argument that is not a variable.

Under `--share-strings` nothing is refused here: the same 9,028 give 8,613 with master's C and 415 refused on both. The rule shares the parameter where the method answers it, as the example does; where the method answers something else (`nil`, `out.size`) the flag loses the append, with this change as without. The five reject tests are in `test/share/reject.list` with CRuby's answers.

**Not in this change.** Of the programs it leaves, 477 are silently wrong on master and stay so: a parameter the method assigns after the append (218), a constant handed over (`V = +"az"`, 114), an Array element or a Hash value handed by the alias's name (55), an alias in `class << self` (30), a Struct member handed by the alias's name (26), a keyword parameter (`def render(out:)`, 22), the caller's parameter handed on through a method written over the old name (`alias plain_render render; def render(out) = plain_render(out)`, 6), a receiver of more than one class (6). So does an instance variable or a global read nowhere else whose method runs twice.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
