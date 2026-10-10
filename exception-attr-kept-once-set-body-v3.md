<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Stated cost, in instructions under callgrind for each exception built, in a
program that has such a class (gcc, glibc on x86-64; a loop of 150,000 turns
less one of 50,000):

| the exception | master | this | the change's own | glibc's string functions |
|---|---|---|---|---|
| a builtin, caught by `rescue StandardError => e` | 2408.74 | +5.00 | +5.00 | 0.00 |
| the class, raised by name, caught by `rescue PErr => e` | 5620.08 | +68.09 | +2.09 | +66.00 |
| `PErr.new("x")` alone | 4473.74 | +24.02 | +2.02 | +22.00 |
| a subclass raised by name, caught by an arm typed to its parent, both such classes | 6288.51 | +85.05 | +24.80 | +60.25 |
| the class, raised by name, caught by `rescue StandardError => e` | 6104.76 | -187.54 | -146.65 | -40.89 |
| a builtin leaving through an ensure with no rescue clause | 2611.51 | +19.00 | +19.00 | 0.00 |
| the class, leaving the same way, caught by `rescue PErr => e` | 6393.53 | -169.70 | -161.68 | -8.02 |
| a builtin raised under a rescue, leaving through such an ensure | 4977.87 | +17.00 | +17.00 | 0.00 |
| the class, raised and leaving the same way, caught by `rescue PErr => e` | 8759.90 | -163.81 | -155.75 | -8.05 |

The change's own is the range test (the 5, whatever the number of classes
and the length of their names), one more argument, in the fourth row the
subclass's own, larger object, and in the sixth and the eighth the tests
ahead of `sp_exc_caught_obj()` and of `sp_exc_ensure_obj()`, a range test in
each. In the second, third and fourth rows the last column is no work this
change adds: the compares are the runtime's walk up the class's ancestry by
name, called the same number of times on both (17,400,000 `strcmp` calls in
the second row's 150,000 turns); in the fifth, the seventh and the last row
the builder asks less. glibc's `strcmp` enters by its page-crossing path
according to the two addresses' offsets in their pages, 11 instructions
dearer, and the class's name is now a row of a table and no longer the
literal. It moves with the layout, so it is shown beside the cost: built
with clang 18.1 that column reads 0.00, -30.00 and +40.25 in those three
rows, and their totals are +2.10, -27.98 and +66.48; the first row is +6.00
there, the sixth +12.00 and the eighth +26.99, all the change's own. A
program with no such class emits the C it did and costs what it did, through
such an ensure too, and a class with an `initialize` of its own costs what
it did, to the instruction. An ensure nothing is raised through costs what
it did in a program that has such a class as well (252.00 a turn on both).
Master ran right, and so gains nothing for what it pays: a program that has
such a class and catches a builtin (the 5, whether or not the class is ever
raised, and the 19 or 17 where the builtin leaves through such an ensure),
and one that stores nothing in the class it builds (the 2; the 25 where the
subclass's attributes are never stored). Compiling a program that only
defines such classes runs about 19,000 more instructions for each of them,
and more for the first (callgrind of `spinel -c`): 1.3% more at 300 classes,
0.6% at 1,000 and 0.4% at 2,000. No other program emits different C. A class
that has an ivar and is no such class is asked once what it is, which costs
the compiler 292 instructions for a class that is no exception (0.02% at 300
of them) and 1,179 for an exception class with an `initialize` of its own
(0.05%); a program with no class of its own runs 340 fewer (`p 1`) to 271
more (seven lines with a rescue). Around that, glibc's string compares cost
more or less for the same calls, by where the strings lie (649,862 `strncmp`
calls on both at 300 plain classes), so the totals move either way with the
run: -0.32% for `p 1`, -0.14% for the seven lines, +0.03% for the 300 plain
classes and +0.01% for optcarrot in one, and -0.30%, -0.11%, +0.03% and
+0.01% in the next.

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

Without the flag the same class was already written past the end of its
object, in a plain run, once a rescue that does not name it had caught it:

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

`sp_exc_new_for_catch` built the caught value as a plain exception of the
base size. The dispatch on the kept value casts it to the class's struct,
and the method stores beyond it. An arm typed to the class's parent, where
the parent is such a class too, built it at the parent's size, and what the
subclass's own arm stores afterwards goes past that
(`test/exception_attribute_parent_arm.rb`: 29 of 30 read back wrong).

A `begin` with an `ensure` holds an exception that leaves through its rescue
clauses, raised in a clause or matched by none, as its object until the
ensure has run ("An ensure runs when the exception leaves through the rescue
clauses"), and built it with `sp_exc_new_for_catch` too: raised in a clause
and caught afterwards by an arm typed to the class, 29 of 30 read back wrong
(`test/exception_attribute_ensure_clause.rb`), without the flag.

An ensure with no rescue clause, a `begin`'s or a method's, makes the object
of a raise that passes through it and holds it for the raise after its body
("An ensure keeps a String raise's message for the raise after it"), with
that function again. The arm typed to the class takes the object it is
handed as the class's struct:

```ruby
class Wide < StandardError
  attr_accessor :a, :b, :c, :d, :e, :f, :g, :h, :i, :j, :k, :l
end

def go
  raise Wide, "wide"
ensure
  $kept = [ArgumentError.new("kept 0"), ArgumentError.new("kept 1")]
end

begin
  go
rescue Wide => x
  x.a = -1; x.b = -2; x.c = -3; x.d = -4; x.e = -5; x.f = -6
  x.g = -7; x.h = -8; x.i = -9; x.j = -10; x.k = -11; x.l = -12
  puts x.a + x.l         # Spinel: segmentation fault; CRuby -13
  puts x.message
end
$kept.each { |o| puts o.class, o.message }
```

That is a segmentation fault in a plain run, with gcc and with clang, with
`--share-strings` and without. With four attributes, each read back, the
program is right in a plain run, by where the stores land, and faults under
`SPINEL_GC_STRESS`. With two, in a loop that keeps the exceptions, nothing
faults and 30 of 30 read back wrong (the same test, whose last part is the
road above, through a method's ensure).

Where a cause waits for the raise, such an ensure, a filter block's and a
`synchronize` body's make the object as they catch it ("An ensure keeps the
cause of a String raise it raises again"), with that function as well:
raised under a rescue and caught afterwards by the arm typed to the class,
39 of 40 read back wrong (the same test), and the program above with its
raise under a rescue is the same segmentation fault.

Built by `.new`, or by a rescue that names it, the object had its own size
and still lost what was stored in it:

```ruby
class ParseError < StandardError; attr_accessor :line, :ctx; end
rows = ->(n) { (0...n).map { |i| [i, "r#{i}"] } }

e = ParseError.new("m")
e.ctx = rows.(3)
20000.times { rows.(3) }
p e.ctx                  # Spinel [1, "r1"], CRuby [[0, "r0"], [1, "r1"], [2, "r2"]]
```

Such a class has no constructor on its path, so the runtime builds it:
`sp_exc_new_sub_sized` gave it the base exception's scan. An ivar the
program stored was never marked, and its value was freed under the
exception.

One builder cures both, which is why they are one change.
`sp_exc_new_sub_ivars` takes the class's own scan; `.new` and the naming
rescue call it. A rescue that names no class of the program holds only the
raised name. The names of these classes stand in one table of the generated
code (`sp_xbn_name`), and that code passes a class's row where it raises or
builds the class, so the rescue knows the class by a range test on the
pointer and builds it with the same builder; `sp_user_exc_parent` is not
asked a second time. A raise that builds the exception itself, and the
ensure that holds one, ask the same entry; where `sp_exc_caught_obj()` would
build one, the generated code builds such a class ahead of the call, and
where `sp_exc_ensure_obj()` would, it calls an entry that builds such a
class first and holds it as that function holds its own; neither function
changes. The catch alone, at the right size but with the base scan, would
trade the write past the end for the freed value above.

Where `sp_exc_new_for_catch` built such a class before, a message given as a
literal stays frozen as it was there (`e.message.frozen?` is true
and `e.message << "x"` raises FrozenError through `rescue StandardError =>
e`): `sp_exc_new_sub_caught` is the same builder with that function's own
test of the message and its root of the caller's message.

A class with an `initialize` of its own was right and keeps
`sp_exc_new_sub_sized`: its C does not change, and `sp_exc_new_for_catch`
does not change. A builtin exception the program reopens (`class
RuntimeError < StandardError; attr_accessor :code; end`) is not such a
class. `sp_exc_disp_heap` is inline by hand, so that `sp_exc_new` costs what
it did: with five callers in place of three, gcc at the Makefile's flags
inlines it into none on its own.

Not in this change: an attribute nothing has stored. The struct is zeroed,
as on master, and zero is not nil in every slot: one the compiler types as
an Integer or as a boxed value reads 0 until it is stored, where CRuby reads
nil:

```ruby
class ParseError < StandardError; attr_accessor :line, :ctx; end
p ParseError.new("m").line   # Spinel 0 on master and with this change, CRuby nil
```

Where master built the object at the base size, that read went past its end
and printed what lay there (a pointer's value, an empty line or 0, by the
run); it reads the object's own zeroed slot now, the 0 above, and a program
that crashed on master ahead of such a read now reaches it. Seeding nil is
left for a change of its own: CRuby runs methods of the program that the
compiler does not (a `to_ary` under a multiple assignment), and where one of
them stores a zero in the attribute, the zeroed slot is CRuby's answer.

The type of the slot is the compiler's, and with `--share-strings` it
follows the form of the raise: an attribute a method stores a String in is a
boxed value where the class is raised by its name with a String the program
appends to (`raise U, s`), and a String, whose unset read is nil, where the
program writes `raise U.new(s)`. Raised with a copy, `raise U.new(s.dup)`,
the slot is the boxed one again, and master prints the 0 this change prints
for `raise U, s`.

Nor whether an attribute was assigned: a zeroed slot of those two kinds
answers a presence read (`instance_variables`, `instance_variable_defined?`)
as assigned, as it does on master for an exception built by `.new`:

```ruby
class ParseError < StandardError; attr_accessor :line, :ctx; end
p ParseError.new("m").instance_variables   # Spinel [:@line, :@ctx] on master and with this change, CRuby []
```

Nor a class read off a value (`raise x.class, "re"`) that an arm naming no
class of the program catches. Its name reaches the raise as a copy, which is
no row, and the arm still builds it at the base size; the arm typed to the
class builds it as itself, unless an ensure held it first: the ensure
builds it at the base size, as on master, and the arm takes that object.
And a subclass caught by an arm
typed to a parent that has a method of its own and no attribute, or by a
bare arm typed to the parent, is still built at the parent's size, as on
master: ivars a method of the subclass stores go past the object.

Nor `cause: nil` on a raise under a rescue that leaves through a method's
ensure: `e.cause` is the exception that was in flight, where CRuby gives
nil, for such a class as for a builtin exception on master.

Test: `test/exception_attribute_without_initialize.rb`,
`test/exception_attribute_marked.rb` (marked `# spinel: gc-stress`),
`test/exception_attribute_parent_arm.rb`,
`test/exception_attribute_ensure_clause.rb`,
`test/share_strings_exception_attribute.rb` (run by `share-strings-test`
too), and one that passes on master too:
`test/exception_attribute_builtin_reopened.rb` (a reopened builtin
exception, built as it was).

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this head in a Linux container (gcc 13, clang 18, CRuby 3.3.6), both sides built with the rbs parser: the six tests pass in twelve cells each (gcc and clang, with and without `--share-strings`, `SPINEL_GC_STRESS` 0, 1 and 2), `tools/gate.rb check` passes with the commit staged, `gc-stress-test`, `int-min-test`, `defer-refusals-test`, `shadow-check`, `inline-rbs-test` and `share-strings-test` pass, and against master the corpus emits the same C for all but twelve programs, with `--share-strings` and without (five of the tests and seven with such a class); those twelve and the sixth test pass in the corpus lane at `-O1`, with `SPINEL_SHARE_STRINGS=1` and without. `share-verify-test` reports no new diagnostic and one failure, in this container, for a program with no such class (`test/share/share_strings_net_http_zlib.rb`, whose C differs with the check flags on master as it does here, byte for byte). The cost table was measured on this head. The `.expected` files match CRuby 3.3.6 run with `--enable-frozen-string-literal`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (the new tests hold none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not: the C is the same with and without this change)
- [x] Depends on: none
