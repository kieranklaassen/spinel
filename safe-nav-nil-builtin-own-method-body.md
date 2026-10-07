<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class String
  def pair(a) = "#{self}-#{a}"
end
s = ARGV.size > 0 ? "s" : nil
p s&.pair(1)
```

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-nil
+"-1"
```

The method ran on the nil, and an argument with an effect ran too. The same for a method added to Integer or Float, and for a builtin's name the program redefines (`s&.upcase` against the program's `def upcase`).

`emit_call_body` asks for a reopened String, Integer, Float, Symbol or Range method ahead of every builtin arm. That site never looked at the operator, so it took the call before the nil guard (`emit_call_safe_nav_arms`) saw it. It now waits while the guard is pending (`sn_guard_pending`), as the chain emitters below it do: the guard re-enters with the receiver in its temp, and the site takes the call then. `emit_call_body` keeps its line count.

"v&.fdiv(2) and the other Ruby-defined Integer methods keep the &." left such a call on its typed emitter; for a method the program defines, that emitter is this site, so an Integer was still wrong.

Not in this change: on an Array, Hash or Object receiver the call answers nil already, but its arguments still run ahead of the guard.

`test/safe_nav_reopened_builtin.rb` prints 23 lines; master prints `"-1"`, `"-2"`, `"-3"` and `"own "` for the four nils and then raises on `nil&.succ`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
