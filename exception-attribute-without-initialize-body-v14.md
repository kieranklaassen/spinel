<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Stated cost, in instructions under callgrind for each exception built, in a
program that has such a class (gcc, glibc on x86-64; a loop of 150,000 turns
less one of 50,000):

| the exception | master | this | the change's own | glibc's string functions |
|---|---|---|---|---|
| a builtin, caught by `rescue StandardError => e` | 2367.7 | +5.0 | +5.0 | 0 |
| the class, raised by name, caught by `rescue PErr => e` | 5607.1 | +86.1 | +20.1 | +66.0 |
| `PErr.new("x")` alone | 4460.8 | +42.0 | +20.0 | +22.0 |
| a subclass raised by name, caught by an arm typed to its parent, both such classes | 6242.5 | +105.0 | +44.8 | +60.2 |
| the class, raised by name, caught by `rescue StandardError => e` | 6074.7 | -173.5 | -132.6 | -40.9 |

The change's own is the range test (the 5, whatever the number of classes and
the length of their names), two more arguments and the nil stores of the
class's attributes (two here), and in the fourth row the subclass's own,
larger object. In the three rows that cost, the last column is no work this
change adds: the compares are the runtime's walk up the class's ancestry by
name, called the same number of times on both (17,400,000 `strcmp` calls in
the second row's 150,000 turns); in the last row the catch asks less.
glibc's `strcmp` enters by its page-crossing path according to the two
addresses' offsets in their pages, 11 instructions dearer, and the class's
name is now a row of a table and no longer the literal: 13 of a turn's 116
compares cross on master's build, 19 on this one. It moves with the layout,
so it is shown beside the cost: built with clang 18.1 that column reads
-66.0, -33.0 and +11.3 in the three rows that cost, and their totals are
-47.9, -15.0 and +55.5. A program with no such class emits the C it
did, and a class with an `initialize` of its own costs what it did, to the
instruction. Master ran right, and so gains nothing for what it pays: a
program that has such a class and catches a builtin (the 5, whether or not
the class is ever raised), and one that never reads an attribute of the
class it builds (the 20; the 45 where the subclass's are never touched).
Compiling a program that only defines such classes runs about 50,000 more
instructions for each of them (callgrind of `spinel -c`): 3.7% more at 300
classes, 1.9% at 1,000 and 1.1% at 2,000; a program with none runs under
0.15% more, and that in glibc's `strcmp` alone.

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
and `ctx` is read from beyond it. An arm typed to the class's parent, where
the parent is such a class too, built it at the parent's size, with the same
read. A method that stores there writes beyond it:

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

Where `sp_exc_new_for_catch` built such a class before, a message given as a
literal stays frozen as it was there (`e.message.frozen?` is true
and `e.message << "x"` raises FrozenError through `rescue StandardError =>
e`): `sp_exc_new_sub_caught` is the same builder with that function's own
test of the message.

A class with an `initialize` of its own was right and keeps
`sp_exc_new_sub_sized`: its C does not change, and `sp_exc_new_for_catch`
does not change. A builtin exception the program reopens (`class
RuntimeError < StandardError; attr_accessor :code; end`) is not such a
class.

"No `initialize` in its chain" is read from the compiler's class table, which
holds what the compiler kept of what it read. Where the analysis settled a
test of the engine and dropped an arm, where a file was not read, where a
module is mixed in or a method is made or named by something the text does
not spell, or where the program gives a class an `exception` of its own,
CRuby may run an `initialize` or an accessor the table does not hold, or
raise another object than the class builds. Master's zeroed slot reads 0
there, and 0 may be what CRuby stored:

```ruby
class Counted < StandardError
  attr_accessor :count
  if RUBY_ENGINE == "ruby"
    def initialize(msg = nil)
      super
      @count = 0
    end
  end
end
p Counted.new("m").count    # Spinel 0, CRuby 0
```

So in such a program these classes are built as on master, and its C does
not change. The first of the four is a new global, `g_engine_decided`, which
`desugar_engine_branches` sets when it has changed the node table: it has
settled a test and dropped what the test rules out. It is new here because
this is the first change to read that fact. The other three are one question
to `an_prog_never_gives`, asked of the word `exception`: it answers "may" for
every name where a file was not read (`g_require_unread`), a module is mixed
in (`include Comparable`) or a name is given by value, so the flag needs no
term of its own; an `exception:` keyword (`Integer(s, exception: false)`) is
that word too. The price is the fix itself: in such a program the faults
above stand. Of the 6,418 test programs 996 are such programs, and 5 of the
14 that hold such a class (three of them the guard tests below).

Not here: a class read off a value (`raise x.class, "re"`). Its name
reaches the raise as a copy, which is no row: no `initialize` runs for it,
and a class without one is still built at the base size. And a subclass
caught by an arm typed to a parent that has a method of its own and no
attribute, or by a bare arm typed to the parent, is still built at the
parent's size, as on master: its attribute does not read nil there, and
ivars a method of the subclass stores go past the object.

Test: `test/exception_attribute_without_initialize.rb`,
`test/exception_attribute_marked.rb` (marked `# spinel: gc-stress`),
`test/exception_attribute_parent_arm.rb`,
`test/share_strings_exception_attribute.rb` (run by `share-strings-test`
too), and four that pass on master too and guard what this change leaves
alone: `test/exception_attribute_builtin_reopened.rb` (a reopened builtin
exception), `test/exception_attribute_engine_test.rb`,
`test/exception_attribute_computed_initialize.rb` and
`test/exception_attribute_own_exception.rb`.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this head in a Linux container (gcc 13, clang 18, CRuby 3.3.6): the eight new tests pass in twelve cells each (gcc and clang, with and without `--share-strings`, `SPINEL_GC_STRESS` 0, 1 and 2), `tools/gate.rb check` passes with the commit staged, `share-strings-test`, `gc-stress-test` and `int-min-test` pass, and against the change this depends on the corpus emits the same C for all but nine programs, with `--share-strings` and without (four of the new tests and five with an exception class that holds an ivar); those nine and the other four new tests pass in the corpus lane at `-O1`, with `SPINEL_SHARE_STRINGS=1` and without. The `.expected` files match CRuby 3.3.6 run with `--enable-frozen-string-literal`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (the new tests hold none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not: the C is master's byte for byte)
- [x] Depends on: "A method added to a builtin runs its receiver before its arguments"
