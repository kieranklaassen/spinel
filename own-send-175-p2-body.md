<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
class Mailer
  def send(msg, flags) = "#{msg}:#{flags}"
end
m = [:sort, :reverse][ARGV.size]
p [3, 1, 2].send(m)        # [1, 2, 3] in CRuby
```

raises `NoMethodError` on master (undefined method 'send' for an instance of Array). A bare `send("on_#{ev}")` in a class with no `send` of its own, `door.public_send(m)` and `door.__send__(m)` are refused. `desugar_dynamic_send` stood down for the whole program as soon as any scope was named `send`, `__send__` or `public_send`, and every other computed send was left an ordinary call that nothing answers.

Now the lowering stands down for a call only where the program's own method can take it (`an_send_may_be_own`): the receiver's class, or a class under it, has the name in its chain; the receiver is boxed or has no type yet; self in a module's method or an `instance_eval` block; the program has a top-level def of the name; or a builtin the program reopened defines it, since `class Object; def send` is every receiver's. Every other call is lowered as it is in a program that defines none. The arms are made while the receiver has one type and a later round can widen it, so the two readers of `dyn_send_arms` ask again and leave the call as it was when the receiver has become one the own method can take.

Not in this change: a computed send on a receiver that is boxed while the fixpoint runs, in a program that defines the name.

`test/computed_send_beside_own_send.rb` prints 16 lines and `test/computed_send_object_send.rb` 12; master refuses both.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (A class's own send takes a literal first argument)
