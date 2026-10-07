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

Size and cost: 775 lines, 528 of them the proofs in `src/analyze_util.c`. Nothing at run time. At compile time, by `spinel-work -c`: a program with no def of the three names pays one scan of its scopes per desugar pass (`test/scale/gen.sh 400`, 26,010 lines: 3,849,004,649 on master and 3,849,004,460 here, a count that moves by a few hundred between runs). A program with one has its text read once: 2,000 defs of `def f(x) = x.send(:hi)` beside an unrelated class's own send, whose C is master's, count 118,119,527 on master and 118,527,949 here (0.35 percent). A call left to the own method is an ordinary call from there on and costs what one costs: 2,000 of them on one local count 49,960,232, and the same program with the method under another name 49,560,125 on master.

`test/send_literal_and_user.rb` says a class that defines its own send is never mistaken for Kernel#send; that held for a runtime first argument only. `desugar_public_send_recv` and `desugar_implicit_send` retarget `r.send(:m, a)` to `r.m(a)` before asking whose `send` it is.

The retarget now stands down where the call is proved the program's own (`send_call_owned`). The proofs place a def by where it stands in the text and take `self` for the object of the def around it, so they are asked only in a program whose text cannot undo either. That is tested once for the program (`own_def_takes_call`, `program_text_listed`), and a program that fails it keeps the retarget in every call, its C master's byte for byte:

- a `require` the parser lifts ahead of its statement (one written in a def, a block or an expression), or an `autoload`: the file's defs stand in the text where the load may never have run;
- an alias of one of the three names, or a def of one that goes on to `super`, to a method object, to another of the three or to any method the program defines: the builtin is what such a body can reach, and the retarget already is that;
- `instance_eval`, `instance_exec`, the `class_` and `module_` forms, `define_method` or `define_singleton_method`, called or written as a Symbol or String a send can carry: a block runs on another object;
- a module with a second body, or an `include`, `prepend` or `extend` that is not a plain line of a class body, a module body or the top level (`extend self` aside): a class gains the name after a call that stands below its def;
- BasicObject, whose objects have no Kernel.

In a program that passes, a call is the own method's by two rules:

- The receiver is an object of a class that has the method, where it stands: `self`, written or implied, outside the block of a `new` or a `define`; `K.new(...)`; a local every write of which is `K.new(...)` and which is written on every path to the read. Or it is a class named by its constant, for a class method.
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

Every other call keeps the retarget and its C: a receiver that may be nil (nil's `send` is Kernel's), a parameter, an instance variable, an element, a boxed value. The call left standing is an ordinary call to the splat check as well (`splat_appended_param`): a String splatted into an own send that appends to it is refused as under any other method name.

Not in this change: the program's own send on a receiver that is not proved, and in a program the list above leaves out, is still read as Kernel's.

`test/own_send_literal_argument.rb` prints 20 lines; master refuses the file. `test/own_send_program_kept.rb` is a program the list leaves out, with an own send that hands the call on, a block run on another object, a module reopened after the call and a BasicObject: 6 lines, right on master, and the same C here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
