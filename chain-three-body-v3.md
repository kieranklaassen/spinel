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

The three go together. For a module that a class and its superclass both name, master runs the lower copy twice and passes the parent's copy by, and the two faults cancel: the first commit alone or the third alone turns programs that are right today wrong, and with the three none is lost. The second alone loses none.

Changed and not made right:

- A program in which the module's method hands its block on (`super(&b)`) into such a chain did not build and now raises NoMethodError by name ("super: no superclass method 'go'"), as master does today for the same module beside another form of the class's own method.
- Where the child's `super` passes an Integer and the module's passes a String to a parent with a single call site, the program printed `[3, 6]`, silently wrong, and now raises TypeError by name.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [x] Depends on: # (A method of a prepended module keeps its local variables) and # (A module the superclass includes is not included again)
