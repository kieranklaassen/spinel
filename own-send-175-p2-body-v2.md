<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Mailer
  def send(msg, flags) = "#{msg}:#{flags}"
end
m = [:sort, :reverse][ARGV.size]
p [3, 1, 2].send(m)
```

```
spinel diff: exception-diff
  exception (ruby):   (none)
  exception (spinel): NoMethodError: undefined method 'send' for an instance of Array
--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +0,0 @@
-[1, 2, 3]
```

One class with a `send` of its own takes the computed send from every other receiver in the program. A bare `send("on_#{ev}")` in a class with none, `door.public_send(m)` and `door.__send__(m)` raise the same way.

`desugar_dynamic_send` stands down for the whole program as soon as any scope is named `send`, `__send__` or `public_send`, and every other computed send is left an ordinary call that nothing answers.

Whose send a call reaches is a matter of its receiver. The lowering now stands down for a call only where the program's own method can take it (`an_send_may_be_own`): the receiver's class, or one under it, has the name; the receiver is boxed or has no type yet; `self` in a module's method or an `instance_eval` block; the program has a top-level def of the name; a builtin the program reopened defines it. Every other call is lowered as it is in a program that defines none. The arms are made while the receiver has one type and a later round can widen it, so their two readers (`infer_call_inner`, `emit_dynamic_send`) ask again.

With the computed send in its body lowered, an own method that goes on to another of the three names takes its literal calls too:

```ruby
class Proxy
  def initialize = @t = Target.new
  def hi = "proxy hi"
  def send(m, *a) = @t.send(m, *a)
end
p Proxy.new.send(:hi)     # printed "proxy hi"; CRuby prints "target hi"
```

A program that now builds and calls its own send on a receiver that is nil still meets master's call of that method with no self (a segmentation fault, or the line the method prints without its self; CRuby raises NoMethodError): the same program with the direct call in the method's body does the same on master.

Cost: none for a program that defines none of the three names (the corpus's C is unchanged). One that does asks the receiver's class at each computed send.

Not in this change: a computed send on a receiver that is boxed while the fixpoint runs, in a program that defines the name, is left as written.

Depends on "A class's own send takes a literal first argument", which brings `own_def_takes_call`.

`test/computed_send_beside_own_send.rb` prints 16 lines and `test/computed_send_object_send.rb` 12; master refuses both files.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
