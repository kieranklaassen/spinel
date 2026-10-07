# encoding: utf-8
Encoding.default_external = Encoding::UTF_8
f = "pr175-pieces-2-3.md"; s = File.read(f)
def rep(s, a, b) = (s.sub!(a) { b } or abort("no match: #{a[0, 60]}"))
rep(s, "(1,164 rows go from loud, refused or wrong to right) and 5 were right and stay right. The rest, each viewed:",
       "(1,164 rows go from loud, refused or wrong to right) and 5 were right and stay right. The rest (every one\nviewed except the L->L group, of which I viewed a sample):")
rep(s, "- \"RULE_B candidate\" 2 programs: `a6_method_call_plain_comp_s` (side find 6) and `a7_s_class_local_nil` (side
  find 8). For both the twin without an own send is wrong on master in the same way, by script; not counted.",
"- \"RULE_B candidate\" 2 programs, not counted: in `a6_method_call_plain_comp_s` the line that overflows the
  stack does so on master too once the line before it is taken out (side find 6, by script); for
  `a7_s_class_local_nil` the twin without an own send prints the same wrong exception class on master (side
  find 8, by script).")
File.write(f, s)
puts "patched"
