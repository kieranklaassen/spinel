<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Conn
  def send(msg, flags) = "#{msg}:#{flags}"
  def hello(k) = "Conn#hello #{k}"
end
puts Conn.new.send("hello", 0)
```

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-hello:0
+Conn#hello 0
```

Without `hello` the program is refused: `undefined method 'hello' for an instance of Conn`. `__send__` and `public_send` go the same way.

`test/send_literal_and_user.rb` says a class that defines its own send is never mistaken for Kernel#send; that held for a runtime first argument only. `desugar_public_send_recv` and `desugar_implicit_send` retarget `r.send(:m, a)` to `r.m(a)` before asking whose `send` it is.

The retarget now stands down where the call is proved the program's own (`send_call_owned`):

- the receiver is an object of a class that has the method, where it stands: `self`, written or implied; `K.new(...)`; a local every write of which is `K.new(...)` and which is written on every path to the read. Or it is a class named by its constant, for a class method;
- no def of the name hands the call on, to `super`, to a method object or to another of the three names, and nothing aliases the name. There the builtin is what the body reaches, and the retarget already is that.

Every other call keeps the retarget and its C: a receiver that may be nil (nil's `send` is Kernel's), a parameter, an instance variable, an element, a boxed value. The call left standing is an ordinary call to the splat check as well (`splat_appended_param`): a String splatted into an own send that appends to it is refused as under any other method name.

Cost: none at run time. A program that defines none of the three names compiles as before (the corpus's C is unchanged); one that does pays a walk of its nodes for each such call on a local.

Not in this change: the program's own send on a receiver that is not proved (a parameter, an instance variable, an element) is still read as Kernel's.

`test/own_send_literal_argument.rb` prints 18 lines, an alias of `__send__` and a `super` in `public_send` first; master refuses the file.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
