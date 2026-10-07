# encoding: utf-8
Encoding.default_external = Encoding::UTF_8
f = "pr175-pieces-2-3.md"; s = File.read(f)
def rep(s, a, b) = (s.sub!(a) { b } or abort("no match: #{a[0, 50]}"))

rep(s, "Width, by hand on p2 and p3 with gcc (`tmp/v_*.rb`): answers of Integer, Float, Symbol, String, an Array read
with `[0]`, a Hash of Integers read with `[1]`, a Hash of Strings read with `.size` all build and are right on
p3; only the Hash of Strings read with `[]` fails.",
"Width, by hand on p2 and p3 with gcc (`tmp/v_*.rb`): answers of Integer, Float, Symbol, String, an Array read
with `[0]`, a Hash of Integers read with `[1]`, a Hash of Strings read with `.size` all build and are right on
p3; only the Hash of Strings read with `[]` fails.

The same cause has a second face, which breaks no rule (wrong before, loud after) but is a case the title
promises: `/home/claude/r8/p175s/find/f7_p3_typeerror.rb`

```ruby
class Own
  def send(msg, flags) = [msg, flags]
  def val(k) = [k, 1]
end
class Plain
  def val(k) = [k, 2]
end
x = ARGV.size == 0 ? Own.new : Plain.new
r = x.send(:val, 1)
p r.first
```

CRuby `:val`; master and p2 (same C) print `1` (the wrong answer the piece is about); p3 raises
`an Array holding Symbol reached a slot typed as an Integer Array (TypeError)`, exit 1, with gcc and clang.
The split by hand (`find/f7_twin_by_hand.rb`) prints `:val` on master, p2 and p3. So where the own send's
answer and the retargeted method's answer are two different Array or Hash types, the variable keeps the
type of the retargeted answer.")

rep(s, "### Finding 3 (piece 2, a note, not a rule count)", "Beside it, not counted against the piece (`tmp/psend_main.rb`): `class Own; def send(msg, flags = 0)`, a
top-level `def ping`, then `p public_send(m)` at the top level. CRuby raises NoMethodError (private method
'ping' called for main); master and p1 refuse; p2 prints `\"top#ping\"`. The twin without the Own class prints
`\"top#ping\"` on master too: master's lowering lets a bare `public_send` call a private top-level def (side
find 7), and piece 2 reaches it. (The sentence in the commit message about a bare `public_send` is about a
program that defines `public_send` itself: the question is asked per name.)

### Finding 3 (piece 2, a note, not a rule count)")

rep(s, "| each arm seen in my programs (routes a1, a2: class, subclass, module method, instance_eval, top-level def, reopened Object/Comparable/Kernel); the body leaves out the bare `public_send` at the top level, which the commit message has |",
"| arms seen in runs: class and subclass (routes a1), module method and instance_eval (a2), reopened Object (the piece's test, `tmp/reopen_obj.rb`), Kernel (`tmp/reopen_kernel.rb`), Comparable and Hash (a1): master's C is kept and is right. The body leaves out the bare `public_send` at the top level, which the commit message has |")

rep(s, "| true (read; the harness routes with a bare public_send at main keep master's C) |",
"| true only for a program that defines `public_send` itself (read in the source: the question is asked per name). In a program that defines `send` alone, a bare `public_send(m)` at the top level is lowered and calls the private top-level def (`tmp/psend_main.rb`: master refuses, p2 prints `\"top#ping\"`, CRuby raises NoMethodError); the twin with no own send does the same on master. TEXT FIX: say \"in a program that defines public_send\" |")

rep(s, "| true (run: reopened Object, Kernel, Comparable routes keep master's C) |",
"| true (run: reopened Object, Kernel, Comparable, Hash keep master's C) |")

rep(s, "6. A literal send on an object-or-nil slot holding the owner:", "6. A bare computed send in a method whose own `send` calls `method(msg).call(*rest)` (`tmp/a6m.rb`): CRuby
   prints `\"Own#ping\"`, master raises SystemStackError.
7. A bare `public_send(m)` at the top level calls a private top-level def (`tmp/psend_main_twin.rb`): CRuby
   raises NoMethodError (private method 'ping' called for main), master prints `\"top#ping\"`.
8. A computed send whose name is nil (`tmp/a7twin.rb`): CRuby raises TypeError (nil is not a symbol nor a
   string), master raises NoMethodError.
9. A literal send on an object-or-nil slot holding the owner:")
File.write(f, s)
puts "patched"
