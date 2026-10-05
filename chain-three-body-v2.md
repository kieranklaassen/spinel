<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Three commits, each one behaviour with its test.

1. A module prepended twice to a class runs once.

```ruby
module Mark
  def trail
    super + [:m]
  end
end
class Root
  def trail
    [:root]
  end
end
class Twice < Root
  prepend Mark
  prepend Mark
  def trail
    super + [:own]
  end
end
p Twice.new.trail    # [:root, :own, :m, :m]; CRuby prints [:root, :own, :m]
```

The same in one call (`prepend Mark, Mark`) and where the class is reopened. `register_prepends` keeps the (class, module) pairs done so far, and `process_prepend_body` leaves a pair alone the second time.

2. A module the class or a superclass has prepended is not included again.

```ruby
class Mixed < Root
  prepend Mark
  include Mark
  def trail
    super + [:own]
  end
end
p Mixed.new.trail    # [:root, :m, :own, :m]; CRuby prints [:root, :own, :m]
```

`register_includes` lists the `prepend` statements of the class bodies before it starts, and `process_include_body` leaves a module alone that the class or a superclass prepends in an earlier statement. `include Mark; prepend Mark` has the module twice, as in CRuby.

3. A super past a prepend reaches the parent's prepended method.

```ruby
module Tens
  def go
    super() { |x| x * 10 }
  end
end
class Parent
  prepend Tens
  def go
    r = []
    r << (yield 1)
    r << (yield 2)
    r
  end
end
class Child < Parent
  prepend Tens
  def go
    super() { |x| x + 1 }
  end
end
p Child.new.go      # [2, 3]; CRuby prints [10, 20]
```

The splice of a yielding parent (`emit_super_inline`) asked the parent's chain for the name of the class's own copy (`__prep_0_go`), and a parent with a prepend of its own holds a method of that name: its own body. It now asks for the method's name, as inference, the call plan and `emit_super` do.

The three go together. For a module that a class and its superclass both name, master runs the lower copy twice and passes the parent's copy by, and the two faults cancel. Above the two pull requests this one depends on, the first commit alone turns 15 programs that are right today wrong, and the third alone 37; the second alone loses none. With the three, none is lost.

Measured from master fa08b100 to this branch, the two pull requests beneath it included, with gcc 13 against CRuby 3.3.6: 9,672 programs (a module prepended or included in a class and in classes under it, its method calling `super` in each way, into plain and yielding parents). 5,248 keep their C and 640 are refused before and after. Of the other 3,784, 972 wrong answers and 408 build failures are right now, 752 are right before and after, and no program that is right on master is lost; 786 do not build, 761 raise and 13 are wrong before and after. Under clang 18.1 a sample of 351 of the changed programs gives the same verdicts as under gcc, on master and on this branch.

Changed and not made right:

- 66 programs in which the module's method hands its block on (`super(&b)` in 64, a bare `super` or `super()` in 2) did not build and now raise NoMethodError by name ("super: no superclass method 'go'"), as master does today for the same module beside another form of the class's own method.
- One probe, where the child's `super` passes an Integer and the module's passes a String to a parent with a single call site, printed `[3, 6]`, silently wrong, and now raises TypeError by name.

Left as on master: a yielding method in a class above the first class that prepends does not build; `prepend M` written inside a module does nothing; `ancestors` lists a module again at an `include` that adds nothing.

Generated C against master fa08b100 (`make cident`), at each of the three commits: 6,111 programs identical; the only C that differs is the new tests' (this branch's three and the two beneath). optcarrot's C is identical. On 9c4eec71 the five commits pick without conflict; the three tests fail there and pass with them.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [x] Depends on: # (A method of a prepended module keeps its local variables) and # (A module the superclass includes is not included again)
