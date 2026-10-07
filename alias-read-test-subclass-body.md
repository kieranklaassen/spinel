<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

The String alias refusals (a copy through a global, through a method that returns its parameter, through a bang method's result) ask whether the other name is read. `sa_read_elsewhere` answers from the variable-site chains: the read nodes of the variable, an instance variable keyed by the class of each node. A subclass's read is another key, so the copy is built with no word:

```ruby
class Doc
  def initialize = @body = +"az"
  def publish
    $last = @body
    $last << "!"
  end
end
class Page < Doc
  def body = @body
end
page = Page.new
page.publish
p page.body
```

```
spinel diff: output-diff
-"az!"
+"az"
```

With `def body = @body` in `Doc` master refuses the program. Two more reads have no read node and pass the same way: a reader (`attr_reader :body`) and an operator write (`s += x`, `@s ||= x`, `$g &&= x`; `s = s + x` is refused).

`sa_read_elsewhere` now asks the three. Operator writes are chained as a site kind of their own (`VS_OPWRITE`), so the Array route's read test, which walks `VS_READ`, answers as before. For an instance variable the classes above and below its own are asked for a reader and for their reads; a class in neither line is not.

1,125 programs (a global in both directions, a returned parameter, a bang method's result, `id(s) << x`; a local, an instance variable, a global; the read spelled each of these ways and plainly; the read after the mutation, before the copy, or never run), master against this:

| on master | with this | programs |
|---|---|---|
| wrong | refused | 228 |
| right | refused | 552 |
| right | right, master's C byte for byte | 140 |
| refused | refused | 177 |
| wrong | wrong | 28 |

The 552 are the cost the routes have today: the read comes before the copy, the reader is never called, or the mutation changes nothing (`<< ""`). For each of the 780 programs refused here, the same program with the read written as a plain read (`def body = @body` in the class, `s = s + x`) is refused on master.

Under `--share-strings` nothing changes (the same 1,125: every answer and all C as on master). The three are asked with the flag off only: asked there, the rule's route check refuses programs the flag compiles correctly.

**Not in this change.** The 28 stay silent: `inspect`, `instance_variable_get`, and an instance variable that may be nil (a reader in a class that never assigns it; the routes ask about String slots only). So do a mutation in a subclass or through a reader (`page.body << x`), and an operator write as the copied value (`$g = (s += x)`).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
