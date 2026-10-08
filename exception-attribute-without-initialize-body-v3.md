<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Stated cost: in a program that has such a class, a rescue pays one range
test (5 instructions under callgrind) for each exception it builds from a
raised name, whatever the number of classes and the length of their names.
A program with no such class emits the C it did.

With `--share-strings`, an exception class with attributes and no
`initialize` of its own, raised with a String the program appends to, is
written past the end of its object, in a plain run:

```ruby
class Tagged < StandardError; attr_accessor :tag, :at; end

kept = []
60.times do |i|
  s = +"m"
  s << i.to_s
  begin
    raise Tagged, s
  rescue Tagged => e
    e.tag = "tag-#{i}"
    e.at = [i, "a#{i}"]
    kept << e
  end
end
bad = 0
kept.each_with_index do |e, i|
  bad += 1 unless e.tag == "tag-#{i}" && e.at == [i, "a#{i}"] && e.message == "m#{i}" && e.class == Tagged
end
p bad                    # Spinel --share-strings 59, CRuby 0
```

"An exception holds a shared String message as its handle" builds that
exception at the raise, to hold the String, and builds it as a plain
exception of the base size, whatever arm catches it. The arm typed to the
class casts it to the class's struct and stores its ivars beyond it. Before
that change the arm built the exception itself, at the class's size, and the
program printed 0.

Without the flag the same class was already read past the end of its object,
in a plain run, once a rescue that does not name it had caught it:

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
and `ctx` is read from beyond it. An arm typed to the class's parent built
it at the parent's size, with the same read. A method that stores there
writes beyond it:

```ruby
class Marked < StandardError
  attr_reader :a, :b, :c
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
it. A rescue that names no class of the program holds only the raised name.
The names of these classes stand in one table of the generated code
(`sp_xbn_name`), and that code passes a class's row where it raises or
builds the class, so the rescue knows the class by a range test on the
pointer and builds it with the same builder; `sp_user_exc_parent` is not
asked a second time. A raise that builds the exception itself asks the same
entry. The catch alone, at the right size but zeroed and
unmarked, would trade the read past the end for the 0 and the freed value
above.

A class with an `initialize` of its own was right and keeps
`sp_exc_new_sub_sized`: its C does not change, and `sp_exc_new_for_catch`
does not change. A builtin exception the program reopens (`class
RuntimeError < StandardError; attr_accessor :code; end`) is not such a
class.

Not here: a class read off a value (`raise x.class, "re"`). Its name
reaches the raise as a copy, which is no row: no `initialize` runs for it,
and a class without one is still built at the base size.

Test: `test/exception_attribute_without_initialize.rb`,
`test/exception_attribute_marked.rb` (added to `GC_STRESS_TESTS`),
`test/exception_attribute_parent_arm.rb`,
`test/exception_attribute_builtin_reopened.rb`,
`test/share_strings_exception_attribute.rb` (run by `share-strings-test`
too).

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this head in a Linux container (gcc 13, clang 18, CRuby 3.3.6): the five new tests pass in twelve cells each (gcc and clang, with and without `--share-strings`, `SPINEL_GC_STRESS` 0, 1 and 2), `tools/gate.rb check` passes with the commit staged, `share-strings-test` and `int-min-test` pass, and against master the corpus emits the same C for all but eleven programs (four of the new tests and seven with an exception class that holds an ivar). The `.expected` files match CRuby 3.3.6 run with `--enable-frozen-string-literal`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (the new tests hold none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not: the C is master's byte for byte)
- [ ] Depends on: no other pull request
