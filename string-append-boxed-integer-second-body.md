<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Path
  def initialize(s) = @s = s
  def to_str = @s
end
def part(i) = i > 0 ? Path.new("/tmp") : "/"
s = "cd ".dup
v = part(1)
s << v
p s
```

```
spinel diff: output-diff
  program: to_str.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-"cd /tmp"
+"cd #<Path:0xADDR>"
```

With a boxed `:name` the append gave `"k=name"`, where CRuby raises "no implicit conversion of Symbol into String"; nil appended nothing and 1.5 appended `"1.5"`.

`emit_str_append_arg` sent a boxed value that is no Integer through `sp_poly_to_s`, the conversion of `puts` and interpolation. An append takes `sp_poly_arg_str_chk`, as a typed argument already does: a String is itself, an object is asked for `to_str`, and anything else is the TypeError that names its class. `<<` and `concat`, as a statement and as a value.

Cost: none. The strict conversion is the shorter one: an append of a boxed String is 21 instructions cheaper with gcc and 30 with clang (callgrind, 200,000 appends).

Test: `test/string_append_boxed_conversion.rb` (21 of its 22 lines are wrong on master). Above the first pull request, the generated C of 11 more corpus programs changes: seven tests, two benchmarks and two `packages/optparse` tests. All pass.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: "A boxed Integer appended by a statement is a codepoint, as in the value position"
