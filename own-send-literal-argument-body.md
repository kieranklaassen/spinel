<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
class Conn
  def send(msg, flags) = "#{msg}:#{flags}"
  def hello(k) = "Conn#hello #{k}"
end
puts Conn.new.send("hello", 0)   # hello:0 in CRuby
```

prints `Conn#hello 0` on master; without the `hello` the program is refused (`undefined method 'hello' for an instance of Conn`). `test/send_literal_and_user.rb` says a class's own `send` is never mistaken for `Kernel#send`, and that held for a runtime first argument only: `desugar_public_send_recv` and `desugar_implicit_send` retargeted a literal one to the method it names before asking whose `send` it was.

Now the retarget stands down where the receiver's class defines the name: its own def, an inherited or included one, a Struct block's, a class method for a class receiver, the enclosing class's or a top-level def for a bare call. `__send__` and `public_send` go the same way. `splat_appended_param` reads the call left standing as the ordinary call it is, so a String splatted into a `send` that appends to it is refused as under any other method name. A program that defines none of the three names keeps its C: `make cident` counts 6326 identical, 0 differ, and the one refusal change is the new test.

Not in this change: a boxed receiver, and a receiver whose class only a subclass gives the name, are retargeted as before.

`test/own_send_literal_argument.rb` prints 16 lines; master refuses it.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
