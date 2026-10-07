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

A call that gives the own `send` the wrong number of arguments now raises ArgumentError, as CRuby does; master printed the answer of the method the literal names.

Size and cost: 617 lines, 409 of them the proofs in `src/analyze_util.c`. Nothing at run time. At compile time a program with no `def send` pays one scan of its scopes per desugar pass: by `spinel-work -c`, `test/scale/gen.sh 400` (26,010 lines) counts 3,823,076,369 on master and 3,823,076,558 here, and 2,000 literal sends in a program with no own send 154,608,013 and 154,612,016. With an own send in the program the same 2,000 sends count 0.1 percent more where they are retargeted as before, and less where they are left standing (123,428,013 to 103,476,952).

`test/send_literal_and_user.rb` says a class that defines its own send is never mistaken for Kernel#send; that held for a runtime first argument only. `desugar_public_send_recv` and `desugar_implicit_send` retarget `r.send(:m, a)` to `r.m(a)` before asking whose `send` it is.

The retarget now stands down where the call is proved the program's own (`send_call_owned`), by three rules:

- The receiver is an object of a class that has the method, where it stands: `self`, written or implied; `K.new(...)`; a local every write of which is `K.new(...)` and which is written on every path to the read. Or it is a class named by its constant, for a class method.
- No def of the name hands the call on, to `super`, to a method object or to another of the three names, and nothing aliases the name. There the builtin is what the body reaches, and the retarget already is that.
- The method's def has run by the time the call does, as far as the text tells: it stands in a top-level statement ahead of the call's, under nothing but class and module bodies; or in the call's own, with the call inside a def that no statement between the two can run. The rule is there for

  ```ruby
  class Early
    def hi = "hi"
    def run = send(:hi)
    FIRST = new.run
    def send(msg) = "early #{msg}"
  end
  ```

  where `FIRST` is `"hi"`: the class body ran the call before the def. A class reopened further down, or under an `if`, has not given its instances the name yet either.

And `self` counts only outside a block that can run on another object: not in a program that calls `instance_eval`, `instance_exec`, the `class_` and `module_` forms or `define_method`, nor in the block of a `new` or a `define`. That is there for `def ask(o) = o.instance_eval { send(:double, 4) }`, where the block's `self` is `o`.

Every other call keeps the retarget and its C: a receiver that may be nil (nil's `send` is Kernel's), a parameter, an instance variable, an element, a boxed value. The call left standing is an ordinary call to the splat check as well (`splat_appended_param`): a String splatted into an own send that appends to it is refused as under any other method name.

Not in this change: the program's own send on a receiver that is not proved (a parameter, an instance variable, an element, a boxed value) is still read as Kernel's.

`test/own_send_literal_argument.rb` prints 23 lines, an alias of `__send__` and a `super` in `public_send` first; master refuses the file.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
