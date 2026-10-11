<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

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

With the flag, a raise whose message is such a String builds the exception
itself, to hold the String, and builds it as a plain exception of the base
size, whatever arm catches it. The arm typed to the class casts it to the
class's struct and stores its ivars beyond it.

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
ensure has run, and built it with `sp_exc_new_for_catch` too: raised in a
clause and caught afterwards by an arm typed to the class, 29 of 30 read
back wrong (`test/exception_attribute_ensure_clause.rb`), without the flag.

An ensure with no rescue clause, a `begin`'s or a method's, makes the object
of a raise that passes through it and holds it for the raise after its body,
with that function again. The arm typed to the class takes the object it is
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
`--share-strings` and without. It is the same segmentation fault where the
ensure is an inner `begin`'s and the clause that binds the exception is an
outer `begin`'s, with an ensure of its own or without. With four attributes,
each read back, the program is right in a plain run, by where the stores
land, and faults under `SPINEL_GC_STRESS=2`. With two, in a loop that keeps
the exceptions and raises through a `begin`'s ensure, nothing faults and 30
of 30 read back wrong (the same test, which ends with the program above and
with the one whose ensure is an inner `begin`'s).

Where a cause waits for the raise, such an ensure, the frame an `else`
clause has under an ensure, a filter block's and a `synchronize` body's make
the object as they catch it, with that function as well: raised under a
rescue and caught afterwards by the arm typed to the class, 39 of 40 read
back wrong (the same test, and 39 of 40 again where the raise is in an
`else` clause), and the program above with its raise under a rescue is the
same segmentation fault.

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
rescue call it for a class that has an ivar to mark. A rescue that names no
class of the program holds only the raised name. The names of these classes
stand in one table of the generated code (`sp_xbn_name`), and that code
passes a class's row where it raises the class, so the rescue knows the
class by a range test on the pointer and builds it with the same builder;
`sp_user_exc_parent` is not asked a second time. Where the runtime's
`sp_exc_new_for_catch`, `sp_exc_caught_obj` or `sp_exc_ensure_obj` would
build the exception, a program that has such a class calls an entry of its
own generated code in that function's place: a test that hands a row to the
program's maker, out of line, and anything else to the runtime's function.
None of the three changes. The catch alone, at the right size but with the
base scan, would trade the write past the end for the freed value above.

Where `sp_exc_new_for_catch` built such a class before, a message given as a
literal stays frozen as it was there (`e.message.frozen?` is true and
`e.message << "x"` raises FrozenError through `rescue StandardError => e`):
`sp_exc_new_sub_caught` is the same builder with that function's own test
of the message and its root of the caller's message. It calls
`sp_exc_new_sub_ivars` and holds no third copy of the body.

A class with an `initialize` of its own was right and keeps
`sp_exc_new_sub_sized`: its C does not change, and `sp_exc_new_for_catch`
does not change. Such a class whose ivars are all unboxed (two Integers,
say) keeps it too where master built it at its own size, at `.new` and at
the rescue that names it: the base scan marks all such an object holds
(`class_needs_scan` is the test master has for it). A rescue whose class
has such a class under it compares the raised name with its own row first
and builds its own class by the call it had; any other name goes to one
function of the generated code, out of line (`sp_exc_arm_other`), which
hands a row to the table and builds a name that is no row as the rescue
would. Either way is one call with nothing kept across it. With the table's
call in line the name and the message live across it, and gcc saves one
more register in the function around the rescue: 2 instructions on every
call of a method that holds one, raised or not. A builtin exception the
program reopens
(`class RuntimeError < StandardError; attr_accessor :code; end`) is not
such a class.

What the cure costs, in instructions under callgrind for one exception
built, in a program that has such a class (x86-64, glibc; a loop of 150,000
turns less one of 50,000; master's count and the change, the program's C
compiled by gcc 13 and by clang 18; spinel and its runtime are built by gcc
13 at the Makefile's flags under both):

| the exception | master, gcc | change | master, clang | change |
|---|---|---|---|---|
| a builtin, caught by `rescue StandardError => e` | 2402.79 | +5.93 | 2470.64 | +4.99 |
| the class, raised by name, caught by `rescue PErr => e` | 5490.12 | +70.03 | 5501.24 | +4.10 |
| `PErr.new("x")` alone | 4337.79 | +56.95 | 4469.22 | -46.98 |
| a subclass raised by name, caught by an arm typed to its parent, both such classes | 6163.49 | +66.07 | 6203.27 | +33.48 |
| the class, raised by name, caught by `rescue StandardError => e` | 5977.79 | -145.58 | 6073.67 | -215.26 |
| a builtin leaving through an ensure with no rescue clause | 2602.49 | +8.00 | 2614.55 | +5.00 |
| the class, leaving the same way, caught by `rescue PErr => e` | 6263.48 | -135.67 | 6290.58 | -236.83 |
| a builtin raised under a rescue, leaving through such an ensure | 4932.85 | +16.98 | 4866.95 | +20.00 |
| the class, raised and leaving the same way, caught by `rescue PErr => e` | 8593.85 | -123.79 | 8540.97 | -226.96 |

Master ran the first, sixth and eighth rows' programs right, a builtin
exception in a program that has such a class, and they pay for the entry's
test: 6, 8 and 17 instructions with gcc and 5, 5 and 20 with clang; a
program that stores nothing in the class it builds pays too, in the second,
third and fourth rows. Of those three rows' change, 66.00, 53.00 and 33.25
with gcc and 0.00, -51.00 and 2.25 with clang are glibc's string compares,
called the same number of times on both sides: a raise passes the class's
row in a table and no longer the literal, the program's other strings lie
where the table leaves them, and `strcmp` and `strncmp` take their
page-crossing path or not by the two addresses' offsets in their pages; the
change's own there is 4.03, 3.95 and 32.82 with gcc and 4.10, 4.02 and 31.23
with clang, for one more argument and, in the fourth row, the arm's compare,
the function out of line, the table and the subclass's own larger object (in
five programs of the fourth row's shape, 20.00 to 32.82 with gcc and 18.54
to 31.23 with clang). The one more argument is the class's scan, and only a
class with an attribute to mark pays it (one the program stores nothing in,
as in these rows, has its slots boxed): with two attributes that only ever
hold Integers, the second and third rows' programs are built by master's own
call and the change's own is 0.00 and 0.01 with gcc and 0.01 and 0.00 with
clang, so that all such a class pays is glibc's share with gcc, the same
66.00 and 53.00. Where the fourth row's arm catches the parent itself, the
arm compares the raised name with its own class's row and builds the parent
by its own call: the change's own is 9.01 with gcc and 6.02 with clang, the
compare and the one more argument (in three programs of that shape, 7.16 to
9.01 and 6.01 to 6.03), and glibc's share there is -86.00 and -44.00; for a
parent of Integer attributes alone it is the compare alone, in five programs
of that shape 2.98 to 3.01 with gcc and -1.00 to 4.02 with clang. Where
nothing is raised a program that has such a class runs what it did with gcc,
by measure: of fifty-two programs with an ensure, a rescue, an `else` clause
under an ensure, a `synchronize` body or a filter block that nothing is
raised through, fifty have such a class, twenty-three of them at a rescue
typed to a class that another such class descends from, eleven of those
inside a method, and none of the fifty costs more with gcc. With clang
forty-five cost the same and five cost 1 or 2 more (106 to 107, 147 to 148,
98 to 100 twice, 76 to 77), each at a rescue arm typed to such a class that
is never taken: the arm's statement is not reached, and clang lays out the
function around it differently. Compiling a program that only defines such
classes runs 16,500 to 19,600 more instructions for each of them (callgrind
of `spinel -c`, spinel built by gcc 13 at the Makefile's flags), 1.3% more
at 300 classes, 0.5% at 1,000 and 0.3% at 2,000; a program with no such
class emits the C it did, and a class with an `initialize` of its own costs
what it did with both compilers.

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
And a subclass caught by an arm typed to a parent that has a method of its
own and no attribute, or by a bare arm typed to the parent, is still built
at the parent's size, as on master: ivars a method of the subclass stores
go past the object.

Nor the cause of an exception object raised under a rescue and leaving
through an ensure (`raise Tagged.new("t")` there): `e.cause` is nil on
master and with this change, for a builtin exception object too, where
CRuby reads the rescued exception. A program that crashed on master ahead
of that read now reaches it.

Nor a String Range held in such a class's attribute under `--share-strings`:
at `SPINEL_GC_STRESS=2` a Range of two Strings the program appended to reads
back wrong by `first` and `last` in 40 of 40, exit 0, where master stops on
a segmentation fault; the same program with a plain class in the exception's
place (`class Box; attr_accessor :span, :tag; end`) prints the same 40 of 40
on master.

This change adds no refusal and lifts none, in the default build or under
any flag.

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

Run on this head in a Linux container (gcc 13, clang 18, CRuby 3.3.6), both sides built with the rbs parser: the six tests pass in twelve cells each (gcc and clang, with and without `--share-strings`, `SPINEL_GC_STRESS` 0, 1 and 2) and under `--int-overflow=wrap` and `--int-overflow=promote`, `tools/gate.rb check-range` over the commit exits 0 and `tools/gate.rb check` passes with the commit staged, `gc-stress-test`, `int-min-test`, `defer-refusals-test`, `shadow-check`, `inline-rbs-test` and `share-strings-test` pass, and against master the corpus emits the same C for all but twelve programs, with `--share-strings` and without (five of the tests and seven with such a class); those twelve and the sixth test pass in the corpus lane at `-O1`, with `SPINEL_SHARE_STRINGS=1` and without. `share-verify-test` fails in this container as it fails there on master, in the same words: one failure (`test/share/share_strings_net_http_zlib.rb`, whose C differs with the check flags) and two new diagnostics (`test/share/share_strings_exception_dispatch.rb`), for two programs with no such class. `share-check-test` fails there as it fails on master too, in the same ten lines (`test/share_check/send_arms.rb`: its recorded report counts 160 marks, the run 159), for a program whose C is the same with and without this change. The cost table was measured on this head. The `.expected` files match CRuby 3.3.6 run with `--enable-frozen-string-literal`; this container has no CRuby 4.0, so neither gate check compared them with one.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (compared with CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (the new tests hold none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not: the C is the same with and without this change)
- [x] Depends on: none
