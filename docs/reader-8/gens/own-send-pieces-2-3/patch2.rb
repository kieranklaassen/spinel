# encoding: utf-8
Encoding.default_external = Encoding::UTF_8
f = "pr175-pieces-2-3.md"; s = File.read(f)
def rep(s, a, b) = (s.sub!(a) { b } or abort("no match: #{a[0, 50]}"))
rep(s, "9. A literal send on an object-or-nil slot holding the owner:", "9. The corpus test test/post_rest_keyword_hash.rb aborts under SPINEL_GC_STRESS=2 on master, with gcc and
   with clang, twice out of two runs: `*** SPINEL_GC_STRESS: the mark reached a freed slot ***`, exit 134;
   it is right with stress unset and 1. (Seen because one of my corpus programs is that test plus a class.)
10. A literal send on an object-or-nil slot holding the owner:")
rep(s, "- p1 as a fourth tree in the piece 3 runs (m, p2, p3 there) and p3 in the piece 2 runs (m, p1, p2 there); the
  first 149 piece 2 programs and the first 50 piece 3 programs ran on all four.",
"- p1 as a fourth tree in the piece 3 runs (m, p2, p3 there) and p3 in the piece 2 runs (m, p1, p2 there);
  about the first 150 piece 2 programs and the first 50 piece 3 programs ran on all four. In every piece 2
  program run (`ga`), p1's C equals master's, so the two piece 2 tables are the same table.
- A true master column for the corpus family `gc`: master refuses all 45, because the line I appended
  (`ZzMailer.new.send(\"x\", 1)`) is piece 1's own case. So for `gc` only the p1 -> p2 table says what piece 2
  changes; the master -> p2 table says only how p2 ends.")
File.write(f, s)
puts "patched"
