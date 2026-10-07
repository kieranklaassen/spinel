<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`Err = Class.new(StandardError)`, the usual spelling of a custom error, defined
nothing: a raised `Err` went past `rescue StandardError`, and `Err.new` raised
NameError.

```ruby
Err = Class.new(StandardError)
begin
  raise Err, "x"
rescue StandardError => e
  puts "got #{e.message}"
end
```

CRuby prints `got x`; Spinel died with `x (Err)`, uncaught.
`desugar_class_new_blocks` turns only the block form into a class, so the
blockless call under a constant write left a name with no class behind it.

The assignment is now the class `class Err < StandardError; end` defines, and
the program compiles to the C that declaration compiles to. It is taken only
where the text settles that the two are the same program: the assignment is a
statement of the program or of a class or module body; the name is declared
nowhere else and named nowhere before it; and the parent is a class declared
before it in an enclosing body, or Object, BasicObject or a builtin exception
the program does not declare. Any other blockless `Class.new` is the call it
was and compiles as before: in a condition, a block or a `begin`, assigned
twice, read first, or given a module, a builtin value class, a Struct, a path
or an expression as parent. `docs/limitations.md` says which are taken.

Not here: a method can be called above its `def`, as with any class.

```ruby
begin
  early
  puts "there"
rescue NameError
  puts "not yet"
end
Err = Class.new(StandardError)
def early = Err.new("e")
```

CRuby prints `not yet`, `early` being undefined there. Master printed `not
yet` too, for the NameError of `Err`; it now prints `there`, which is what
master prints with `class Err < StandardError; end` on that line, from the
same C.

Not here either, wrong on master for a class written with the keyword and the
same now, with the same C: `e.respond_to?(:message)` on an instance of the
program's own exception class, `e.equal?(made)` after `raise made`,
`e.class.superclass == Base`, a rescue arm for a class with a method of its
own asked `is_a?` of a subclass, and a subclass that defines `initialize` and
another method.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: the pull request "A boxed exception of a program's own class answers is_a?, instance_of? and when" (its commit is the first of the two here, the same SHA)
