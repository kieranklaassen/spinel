# encoding: utf-8
Encoding.default_external = Encoding::UTF_8
f = "pr175-pieces-2-3.md"; s = File.read(f)
def rep(s, a, b) = (s.sub!(a) { b } or abort("no match: #{a[0, 60]}"))
a = s.index("11. A computed send that carries a block does not build") or abort "a"
b = s.index("10. A literal send on an object-or-nil slot holding the owner:") or abort "b"
item11 = s[a...b]; rest10 = s[b..]
s = s[0...a] + rest10.sub(/\s*\z/, "\n") + item11.sub(/\s*\z/, "\n")
rep(s, "titles 65 and 65 characters", "titles 64 and 64 characters")
rep(s, "6. A bare computed send in a method whose own `send` calls `method(msg).call(*rest)` (`tmp/a6m.rb`): CRuby",
       "6. A computed send to an object whose own `send` calls `method(msg).call(*rest)` (`tmp/a6m.rb`): CRuby")
rep(s, "aborts under SPINEL_GC_STRESS=2 on master, with gcc and
   with clang, twice out of two runs:", "aborts under SPINEL_GC_STRESS=2 on master, with gcc (two runs of two) and
   with clang (one run):")
File.write(f, s)
puts "patched"
