<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An exception class with attributes and no `initialize` of its own was read
past the end of its object, in a plain run, once a rescue that does not name
it had caught it.

```ruby
class ParseError < StandardError; attr_accessor :line, :ctx; end
kept = []
begin
  raise ParseError, "m"
rescue StandardError => e
  kept << e
end
kept.each { |v| p v.ctx if v.respond_to?(:ctx) }    # Spinel 0, CRuby nil
```

`sp_exc_new_for_catch` built the caught value as a plain exception of the
base size. The dispatch on the kept value casts it to the class's struct,
and `ctx` is read from beyond it. A method that stores there writes beyond
it:

```ruby
class Marked < StandardError
  def mark!(a, b, c)
    @a = a; @b = b; @c = c
  end
end
kept = []
5.times { |i| begin; raise Marked, "a#{i}"; rescue StandardError => e; kept << e; end }
kept.each { |v| v.mark!("1" + v.message, "2" + v.message, "3" + v.message) if v.respond_to?(:mark!) }
n = 0
100_000.times { |i| n += "x#{i}".size }
p n                      # Spinel: segmentation fault; CRuby 588890
```

Built by `.new`, or by a rescue that names it, the object had its own size
and still lost its attributes:

```ruby
class ParseError < StandardError; attr_accessor :line, :ctx; end
def rows(n) = (0...n).map { |i| [i, "r#{i}"] }

e = ParseError.new("m")
p e.line                 # Spinel 0, CRuby nil
e.ctx = rows(3)
20000.times { rows(3) }
p e.ctx                  # Spinel [1, "r1"], CRuby [[0, "r0"], [1, "r1"], [2, "r2"]]
```

Such a class has no constructor on its path, so the runtime builds it:
`sp_exc_new_sub_sized` zeroed the struct and gave it the base exception's
scan. An ivar nothing had set read as the zero pattern, 0 for a boxed or an
Integer slot, where a constructor seeds nil (`e.line ||= 1` kept 0); an ivar
the program stored was never marked, and its value was freed under the
exception.

One builder cures both, which is why they are one change.
`sp_exc_new_sub_ivars` takes the class's own scan and a function that seeds
the slots whose nil is not zero (`sp_<Class>__ivnil`, emitted beside the
scan of such a class and only for one); `.new` and the naming rescue call
it. In a program that has such a class, a rescue that names no class of
the program calls `sp_exc_new_for_catch_own`, which asks the program first
(`sp_user_exc_new_fn`, a hook set as `sp_user_exc_parent_fn` is) and builds
such a class by its name with the same builder. The catch alone, at the
right size but zeroed and unmarked, would trade the read past the end for
the 0 and the freed value above.

A class with an `initialize` of its own was right and keeps
`sp_exc_new_sub_sized`: its C does not change. A program with no class that
has attributes and no `initialize` emits the C it did, and
`sp_exc_new_for_catch` is as it was.

Cost (callgrind, 200,000 times each), all of it in a program that has such
a class: 21 instructions more for a raise and rescue of one (0.4%), 19 more
for a `.new`, 25 more for a builtin exception caught by `rescue
StandardError => e`. A program that has none costs what it did, to the
instruction.

Not here: a class with an `initialize` of its own raised through a Class
value (`raise k, "m"`). No `initialize` runs for it, and it is still built
at the base size.

Test: `test/exception_attribute_without_initialize.rb`,
`test/exception_attribute_marked.rb` (added to `GC_STRESS_TESTS`).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
