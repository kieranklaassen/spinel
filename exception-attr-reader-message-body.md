<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class ParseError < StandardError
  attr_reader :message
  def initialize(text, line)
    super("parse error")
    @message = "#{text} at line #{line}"
  end
end
begin
  raise ParseError.new("unexpected end", 3)
rescue ParseError => e
  p e.message
end
```

```
spinel diff: output-diff
  program: reader.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-"unexpected end at line 3"
+"parse error"
```

With `def message = @message` in place of the declaration it was right. Exception#message is answered through dispatchers that know a class's own `def message`; a reader declared by `attr_reader`, `attr` or `attr_accessor` is no def, so a rescue's `e.message` answered the stored message and never `@message`.

The declaration becomes the def it stands for, before the scope pass (`desugar_exception_message_reader`):

```ruby
attr_accessor :code, :message
# -> attr_accessor :code; attr_writer :message; def message = @message
```

Only in a class written with a superclass that names an exception: a builtin one, or a class of the program whose every definition is found so. A class that says more about the name is left as it was: its own def, an alias to it, an undef, a call on self that names it, a bare `private` or `protected`. The C of a program the pass rewrites is the C of the same program with the def written out (where the declaration lists other names too, the table of symbol names comes in another order), so a rewritten program is as right as that one is.

Not here: a reader declared in a reopening that names no superclass, or in a `Class.new(StandardError)` block, is still not the message.

Test: `test/exception_subclass_message_reader.rb` (6 of its 14 lines are wrong on master). No corpus program's generated C changes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
