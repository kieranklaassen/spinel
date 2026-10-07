<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
class Conn
  def initialize(tag) = @tag = tag
  def send(msg, flags) = "#{@tag}:#{msg}:#{flags}"
  def hello(k) = "Conn#hello #{k}"
end

class Hub
  def initialize = @conns = []
  def add(c) = @conns << c
  def hello = @conns.each { |c| puts c.send("hello", 0) }
end

h = Hub.new
h.add(Conn.new(:a))
h.hello                      # a:hello:0 in CRuby
```

prints `Conn#hello 0` on master. The block parameter is boxed while the fixpoint runs, so the retarget in `desugar_public_send_recv` cannot read off whose `send` it is, and waiting does not help: the Array gets its class only in the re-narrow, after the last round.

Now, in a program that defines the name, the retarget on a boxed receiver goes ahead as before and marks the call. Once the re-narrow has run, `desugar_send_settled` asks again. A receiver now typed with a class that owns the name gets its call back. One still boxed becomes `(__r = recv; __r.is_a?(Conn) ? __r.send("hello", 0) : __r.hello(0))` over the classes that define the name, the shape `desugar_builtin_enum_calls` gives a boxed receiver beside a class's own `each`. Every other call stays the retargeted call it was. A call that changed is one no round has seen, so the rounds run once more for it (`an_infer_fixpoint_rounds`); a program that defines none of the three names is never marked.

Not in this change: a send that carries a block, a send of a send, and a program where a singleton, an unnamed Struct or a reopened builtin defines the name are retargeted as before.

`test/own_send_boxed_receiver.rb` prints 25 lines; master prints 2 and raises NoMethodError.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (A class's own send takes a literal first argument; A computed send beside a class's own send still names its method)
