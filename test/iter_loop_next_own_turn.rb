# A `next` in the block of a String's line, character, byte and codepoint
# iterators, of Array#each_index and of Array.new ends one turn of that
# loop and nothing else: the rescue and the ensure around the call stay
# where they are, an ensure inside the block runs and the turn is over,
# and a proc around the loop goes on.

# under a begin: the raise after the loop is rescued
n = 0
begin; "a\nbb\nc".each_line { |x| next if x.size > 2; n += 1 }; raise "late"; rescue => e; puts "each_line: " + n.to_s + " " + e.message; end
n = 0
begin; "a\nbb\nc".lines { |x| next if x.size > 2; n += 1 }; raise "late"; rescue => e; puts "lines: " + n.to_s + " " + e.message; end
n = 0
begin; "a\nbb\nc".each_line(chomp: true) { |x| next if x.size > 1; n += 1 }; raise "late"; rescue => e; puts "each_line chomp: " + n.to_s + " " + e.message; end
n = 0
begin; "a,bb,c".each_line(",") { |x| next if x.size > 2; n += 1 }; raise "late"; rescue => e; puts "each_line sep: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".each_char { |x| next if x == "b"; n += 1 }; raise "late"; rescue => e; puts "each_char: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".each_byte { |x| next if x == 98; n += 1 }; raise "late"; rescue => e; puts "each_byte: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".each_grapheme_cluster { |x| next if x == "b"; n += 1 }; raise "late"; rescue => e; puts "each_grapheme_cluster: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".each_codepoint { |x| next if x == 98; n += 1 }; raise "late"; rescue => e; puts "each_codepoint: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].each_index { |x| next if x == 1; n += 1 }; raise "late"; rescue => e; puts "each_index: " + n.to_s + " " + e.message; end
n = 0
begin; Array.new(3) { |x| next 0 if x == 1; n += 1 }; raise "late"; rescue => e; puts "Array.new: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".chars { |x| next if x == "b"; n += 1 }; raise "late"; rescue => e; puts "chars: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".bytes { |x| next if x == 98; n += 1 }; raise "late"; rescue => e; puts "bytes: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".codepoints { |x| next if x == 98; n += 1 }; raise "late"; rescue => e; puts "codepoints: " + n.to_s + " " + e.message; end
n = 0
begin; { "a" => [1, 2, 3], "n" => 1 }["a"].each_index { |x| next if x == 1; n += 1 }; raise "late"; rescue => e; puts "boxed each_index: " + n.to_s + " " + e.message; end
n = 0
begin; ["a", "b", "c"].each_index { |x| next if x == 1; n += 1 }; raise "late"; rescue => e; puts "String each_index: " + n.to_s + " " + e.message; end
n = 0
begin; [1, "a", nil].each_index { |x| next if x == 1; n += 1 }; raise "late"; rescue => e; puts "mixed each_index: " + n.to_s + " " + e.message; end

# under an ensure: it runs once, after the loop
n = 0
begin; "a\nbb\nc".each_line { |x| next if x.size > 2; n += 1 }; ensure; puts "each_line ensure: " + n.to_s; end
puts n
n = 0
begin; "a\nbb\nc".lines { |x| next if x.size > 2; n += 1 }; ensure; puts "lines ensure: " + n.to_s; end
puts n
n = 0
begin; "a\nbb\nc".each_line(chomp: true) { |x| next if x.size > 1; n += 1 }; ensure; puts "each_line chomp ensure: " + n.to_s; end
puts n
n = 0
begin; "a,bb,c".each_line(",") { |x| next if x.size > 2; n += 1 }; ensure; puts "each_line sep ensure: " + n.to_s; end
puts n
n = 0
begin; "abc".each_char { |x| next if x == "b"; n += 1 }; ensure; puts "each_char ensure: " + n.to_s; end
puts n
n = 0
begin; "abc".each_byte { |x| next if x == 98; n += 1 }; ensure; puts "each_byte ensure: " + n.to_s; end
puts n
n = 0
begin; "abc".each_grapheme_cluster { |x| next if x == "b"; n += 1 }; ensure; puts "each_grapheme_cluster ensure: " + n.to_s; end
puts n
n = 0
begin; "abc".each_codepoint { |x| next if x == 98; n += 1 }; ensure; puts "each_codepoint ensure: " + n.to_s; end
puts n
n = 0
begin; [1, 2, 3].each_index { |x| next if x == 1; n += 1 }; ensure; puts "each_index ensure: " + n.to_s; end
puts n
n = 0
begin; Array.new(3) { |x| next 0 if x == 1; n += 1 }; ensure; puts "Array.new ensure: " + n.to_s; end
puts n
n = 0
begin; "abc".chars { |x| next if x == "b"; n += 1 }; ensure; puts "chars ensure: " + n.to_s; end
puts n
n = 0
begin; "abc".bytes { |x| next if x == 98; n += 1 }; ensure; puts "bytes ensure: " + n.to_s; end
puts n
n = 0
begin; "abc".codepoints { |x| next if x == 98; n += 1 }; ensure; puts "codepoints ensure: " + n.to_s; end
puts n
n = 0
begin; { "a" => [1, 2, 3], "n" => 1 }["a"].each_index { |x| next if x == 1; n += 1 }; ensure; puts "boxed each_index ensure: " + n.to_s; end
puts n
n = 0
begin; ["a", "b", "c"].each_index { |x| next if x == 1; n += 1 }; ensure; puts "String each_index ensure: " + n.to_s; end
puts n
n = 0
begin; [1, "a", nil].each_index { |x| next if x == 1; n += 1 }; ensure; puts "mixed each_index ensure: " + n.to_s; end
puts n

# an ensure inside the block: the next runs it and skips the rest of the turn
n = 0
"a\nbb\nc".each_line { |x| begin; next if x.size > 2; n += 1; ensure; n += 10; end; n += 100 }
puts "each_line inner ensure: " + n.to_s
n = 0
"a\nbb\nc".lines { |x| begin; next if x.size > 2; n += 1; ensure; n += 10; end; n += 100 }
puts "lines inner ensure: " + n.to_s
n = 0
"a\nbb\nc".each_line(chomp: true) { |x| begin; next if x.size > 1; n += 1; ensure; n += 10; end; n += 100 }
puts "each_line chomp inner ensure: " + n.to_s
n = 0
"a,bb,c".each_line(",") { |x| begin; next if x.size > 2; n += 1; ensure; n += 10; end; n += 100 }
puts "each_line sep inner ensure: " + n.to_s
n = 0
"abc".each_char { |x| begin; next if x == "b"; n += 1; ensure; n += 10; end; n += 100 }
puts "each_char inner ensure: " + n.to_s
n = 0
"abc".each_byte { |x| begin; next if x == 98; n += 1; ensure; n += 10; end; n += 100 }
puts "each_byte inner ensure: " + n.to_s
n = 0
"abc".each_grapheme_cluster { |x| begin; next if x == "b"; n += 1; ensure; n += 10; end; n += 100 }
puts "each_grapheme_cluster inner ensure: " + n.to_s
n = 0
"abc".each_codepoint { |x| begin; next if x == 98; n += 1; ensure; n += 10; end; n += 100 }
puts "each_codepoint inner ensure: " + n.to_s
n = 0
[1, 2, 3].each_index { |x| begin; next if x == 1; n += 1; ensure; n += 10; end; n += 100 }
puts "each_index inner ensure: " + n.to_s
n = 0
Array.new(3) { |x| begin; next 0 if x == 1; n += 1; ensure; n += 10; end; n += 100 }
puts "Array.new inner ensure: " + n.to_s
n = 0
"abc".chars { |x| begin; next if x == "b"; n += 1; ensure; n += 10; end; n += 100 }
puts "chars inner ensure: " + n.to_s
n = 0
"abc".bytes { |x| begin; next if x == 98; n += 1; ensure; n += 10; end; n += 100 }
puts "bytes inner ensure: " + n.to_s
n = 0
"abc".codepoints { |x| begin; next if x == 98; n += 1; ensure; n += 10; end; n += 100 }
puts "codepoints inner ensure: " + n.to_s
n = 0
{ "a" => [1, 2, 3], "n" => 1 }["a"].each_index { |x| begin; next if x == 1; n += 1; ensure; n += 10; end; n += 100 }
puts "boxed each_index inner ensure: " + n.to_s
n = 0
["a", "b", "c"].each_index { |x| begin; next if x == 1; n += 1; ensure; n += 10; end; n += 100 }
puts "String each_index inner ensure: " + n.to_s
n = 0
[1, "a", nil].each_index { |x| begin; next if x == 1; n += 1; ensure; n += 10; end; n += 100 }
puts "mixed each_index inner ensure: " + n.to_s

# a rescue inside the block: the next pops that frame alone
n = 0
begin; "a\nbb\nc".each_line { |x| begin; next if x.size > 2; n += 1; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "each_line inner rescue: " + n.to_s + " " + e.message; end
n = 0
begin; "a\nbb\nc".lines { |x| begin; next if x.size > 2; n += 1; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "lines inner rescue: " + n.to_s + " " + e.message; end
n = 0
begin; "a\nbb\nc".each_line(chomp: true) { |x| begin; next if x.size > 1; n += 1; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "each_line chomp inner rescue: " + n.to_s + " " + e.message; end
n = 0
begin; "a,bb,c".each_line(",") { |x| begin; next if x.size > 2; n += 1; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "each_line sep inner rescue: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".each_char { |x| begin; next if x == "b"; n += 1; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "each_char inner rescue: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".each_byte { |x| begin; next if x == 98; n += 1; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "each_byte inner rescue: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".each_grapheme_cluster { |x| begin; next if x == "b"; n += 1; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "each_grapheme_cluster inner rescue: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".each_codepoint { |x| begin; next if x == 98; n += 1; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "each_codepoint inner rescue: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].each_index { |x| begin; next if x == 1; n += 1; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "each_index inner rescue: " + n.to_s + " " + e.message; end
n = 0
begin; Array.new(3) { |x| begin; next 0 if x == 1; n += 1; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "Array.new inner rescue: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".chars { |x| begin; next if x == "b"; n += 1; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "chars inner rescue: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".bytes { |x| begin; next if x == 98; n += 1; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "bytes inner rescue: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".codepoints { |x| begin; next if x == 98; n += 1; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "codepoints inner rescue: " + n.to_s + " " + e.message; end
n = 0
begin; { "a" => [1, 2, 3], "n" => 1 }["a"].each_index { |x| begin; next if x == 1; n += 1; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "boxed each_index inner rescue: " + n.to_s + " " + e.message; end
n = 0
begin; ["a", "b", "c"].each_index { |x| begin; next if x == 1; n += 1; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "String each_index inner rescue: " + n.to_s + " " + e.message; end
n = 0
begin; [1, "a", nil].each_index { |x| begin; next if x == 1; n += 1; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "mixed each_index inner rescue: " + n.to_s + " " + e.message; end

# an ensure in a begin/rescue inside the block: the next leaves both, and
# the frame of that begin/rescue with them
n = 0
begin; "a\nbb\nc".each_line { |x| begin; begin; next if x.size > 2; n += 1; ensure; n += 10; end; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "each_line ensure in a rescue: " + n.to_s + " " + e.message; end
n = 0
begin; "a\nbb\nc".lines { |x| begin; begin; next if x.size > 2; n += 1; ensure; n += 10; end; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "lines ensure in a rescue: " + n.to_s + " " + e.message; end
n = 0
begin; "a\nbb\nc".each_line(chomp: true) { |x| begin; begin; next if x.size > 1; n += 1; ensure; n += 10; end; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "each_line chomp ensure in a rescue: " + n.to_s + " " + e.message; end
n = 0
begin; "a,bb,c".each_line(",") { |x| begin; begin; next if x.size > 2; n += 1; ensure; n += 10; end; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "each_line sep ensure in a rescue: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".each_char { |x| begin; begin; next if x == "b"; n += 1; ensure; n += 10; end; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "each_char ensure in a rescue: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".each_byte { |x| begin; begin; next if x == 98; n += 1; ensure; n += 10; end; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "each_byte ensure in a rescue: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".each_grapheme_cluster { |x| begin; begin; next if x == "b"; n += 1; ensure; n += 10; end; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "each_grapheme_cluster ensure in a rescue: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".each_codepoint { |x| begin; begin; next if x == 98; n += 1; ensure; n += 10; end; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "each_codepoint ensure in a rescue: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].each_index { |x| begin; begin; next if x == 1; n += 1; ensure; n += 10; end; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "each_index ensure in a rescue: " + n.to_s + " " + e.message; end
n = 0
begin; Array.new(3) { |x| begin; begin; next 0 if x == 1; n += 1; ensure; n += 10; end; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "Array.new ensure in a rescue: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".chars { |x| begin; begin; next if x == "b"; n += 1; ensure; n += 10; end; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "chars ensure in a rescue: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".bytes { |x| begin; begin; next if x == 98; n += 1; ensure; n += 10; end; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "bytes ensure in a rescue: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".codepoints { |x| begin; begin; next if x == 98; n += 1; ensure; n += 10; end; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "codepoints ensure in a rescue: " + n.to_s + " " + e.message; end
n = 0
begin; { "a" => [1, 2, 3], "n" => 1 }["a"].each_index { |x| begin; begin; next if x == 1; n += 1; ensure; n += 10; end; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "boxed each_index ensure in a rescue: " + n.to_s + " " + e.message; end
n = 0
begin; ["a", "b", "c"].each_index { |x| begin; begin; next if x == 1; n += 1; ensure; n += 10; end; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "String each_index ensure in a rescue: " + n.to_s + " " + e.message; end
n = 0
begin; [1, "a", nil].each_index { |x| begin; begin; next if x == 1; n += 1; ensure; n += 10; end; rescue => e2; n += 100; end }; raise "late"; rescue => e; puts "mixed each_index ensure in a rescue: " + n.to_s + " " + e.message; end
# seventy turns of it with no raise at all: no frame is left behind
n = 0
70.times { "ab".each_char { |x| begin; begin; next if x == "a"; n += 1; ensure; n += 10; end; rescue => e2; n += 100; end } }
puts "seventy turns: " + n.to_s
n = 0
70.times { Array.new(2) { |x| begin; begin; next 0 if x == 0; n += 1; ensure; n += 10; end; rescue => e2; n += 100; end } }
puts "seventy turns of Array.new: " + n.to_s

# in a proc: the next ends the loop's turn, not the proc
n = 0
pr0 = proc { "a\nbb\nc".each_line { |x| next if x.size > 2; n += 1 }; 5 }
puts "each_line in a proc: " + pr0.call.to_s + " " + n.to_s
n = 0
pr1 = proc { "a\nbb\nc".lines { |x| next if x.size > 2; n += 1 }; 5 }
puts "lines in a proc: " + pr1.call.to_s + " " + n.to_s
n = 0
pr2 = proc { "a\nbb\nc".each_line(chomp: true) { |x| next if x.size > 1; n += 1 }; 5 }
puts "each_line chomp in a proc: " + pr2.call.to_s + " " + n.to_s
n = 0
pr3 = proc { "a,bb,c".each_line(",") { |x| next if x.size > 2; n += 1 }; 5 }
puts "each_line sep in a proc: " + pr3.call.to_s + " " + n.to_s
n = 0
pr4 = proc { "abc".each_char { |x| next if x == "b"; n += 1 }; 5 }
puts "each_char in a proc: " + pr4.call.to_s + " " + n.to_s
n = 0
pr5 = proc { "abc".each_byte { |x| next if x == 98; n += 1 }; 5 }
puts "each_byte in a proc: " + pr5.call.to_s + " " + n.to_s
n = 0
pr6 = proc { "abc".each_grapheme_cluster { |x| next if x == "b"; n += 1 }; 5 }
puts "each_grapheme_cluster in a proc: " + pr6.call.to_s + " " + n.to_s
n = 0
pr7 = proc { "abc".each_codepoint { |x| next if x == 98; n += 1 }; 5 }
puts "each_codepoint in a proc: " + pr7.call.to_s + " " + n.to_s
n = 0
pr8 = proc { [1, 2, 3].each_index { |x| next if x == 1; n += 1 }; 5 }
puts "each_index in a proc: " + pr8.call.to_s + " " + n.to_s
n = 0
pr9 = proc { Array.new(3) { |x| next 0 if x == 1; n += 1 }; 5 }
puts "Array.new in a proc: " + pr9.call.to_s + " " + n.to_s
n = 0
pr10 = proc { "abc".chars { |x| next if x == "b"; n += 1 }; 5 }
puts "chars in a proc: " + pr10.call.to_s + " " + n.to_s
n = 0
pr11 = proc { "abc".bytes { |x| next if x == 98; n += 1 }; 5 }
puts "bytes in a proc: " + pr11.call.to_s + " " + n.to_s
n = 0
pr12 = proc { "abc".codepoints { |x| next if x == 98; n += 1 }; 5 }
puts "codepoints in a proc: " + pr12.call.to_s + " " + n.to_s
n = 0
pr13 = proc { { "a" => [1, 2, 3], "n" => 1 }["a"].each_index { |x| next if x == 1; n += 1 }; 5 }
puts "boxed each_index in a proc: " + pr13.call.to_s + " " + n.to_s
n = 0
pr14 = proc { ["a", "b", "c"].each_index { |x| next if x == 1; n += 1 }; 5 }
puts "String each_index in a proc: " + pr14.call.to_s + " " + n.to_s
n = 0
pr15 = proc { [1, "a", nil].each_index { |x| next if x == 1; n += 1 }; 5 }
puts "mixed each_index in a proc: " + pr15.call.to_s + " " + n.to_s
count = lambda { |s| k = 0; s.each_line { |l| next if l.strip.empty?; k += 1 }; k }
p count.call("a\n\nb\n")
letters = ->(s) { k = 0; s.each_char { |ch| next if ch == " "; k += 1 }; k }
p letters.call("a b c")

# under a rescue modifier, as a statement and as a method's value
n = 0
("a\nbb\nc".each_line { |x| next if x.size > 2; n += 1 }) rescue n = -1
puts "each_line modifier: " + n.to_s
n = 0
("a\nbb\nc".lines { |x| next if x.size > 2; n += 1 }) rescue n = -1
puts "lines modifier: " + n.to_s
n = 0
("a\nbb\nc".each_line(chomp: true) { |x| next if x.size > 1; n += 1 }) rescue n = -1
puts "each_line chomp modifier: " + n.to_s
n = 0
("a,bb,c".each_line(",") { |x| next if x.size > 2; n += 1 }) rescue n = -1
puts "each_line sep modifier: " + n.to_s
n = 0
("abc".each_char { |x| next if x == "b"; n += 1 }) rescue n = -1
puts "each_char modifier: " + n.to_s
n = 0
("abc".each_byte { |x| next if x == 98; n += 1 }) rescue n = -1
puts "each_byte modifier: " + n.to_s
n = 0
("abc".each_grapheme_cluster { |x| next if x == "b"; n += 1 }) rescue n = -1
puts "each_grapheme_cluster modifier: " + n.to_s
n = 0
("abc".each_codepoint { |x| next if x == 98; n += 1 }) rescue n = -1
puts "each_codepoint modifier: " + n.to_s
n = 0
([1, 2, 3].each_index { |x| next if x == 1; n += 1 }) rescue n = -1
puts "each_index modifier: " + n.to_s
n = 0
(Array.new(3) { |x| next 0 if x == 1; n += 1 }) rescue n = -1
puts "Array.new modifier: " + n.to_s
n = 0
("abc".chars { |x| next if x == "b"; n += 1 }) rescue n = -1
puts "chars modifier: " + n.to_s
n = 0
("abc".bytes { |x| next if x == 98; n += 1 }) rescue n = -1
puts "bytes modifier: " + n.to_s
n = 0
("abc".codepoints { |x| next if x == 98; n += 1 }) rescue n = -1
puts "codepoints modifier: " + n.to_s
n = 0
({ "a" => [1, 2, 3], "n" => 1 }["a"].each_index { |x| next if x == 1; n += 1 }) rescue n = -1
puts "boxed each_index modifier: " + n.to_s
n = 0
(["a", "b", "c"].each_index { |x| next if x == 1; n += 1 }) rescue n = -1
puts "String each_index modifier: " + n.to_s
n = 0
([1, "a", nil].each_index { |x| next if x == 1; n += 1 }) rescue n = -1
puts "mixed each_index modifier: " + n.to_s
def mod0(n)
  ("a\nbb\nc".each_line { |x| next if x.size > 2; n += 1 }) rescue n = -1
  n
end
puts "each_line modifier value: " + mod0(0).to_s
def mod1(n)
  ("a\nbb\nc".lines { |x| next if x.size > 2; n += 1 }) rescue n = -1
  n
end
puts "lines modifier value: " + mod1(0).to_s
def mod2(n)
  ("a\nbb\nc".each_line(chomp: true) { |x| next if x.size > 1; n += 1 }) rescue n = -1
  n
end
puts "each_line chomp modifier value: " + mod2(0).to_s
def mod3(n)
  ("a,bb,c".each_line(",") { |x| next if x.size > 2; n += 1 }) rescue n = -1
  n
end
puts "each_line sep modifier value: " + mod3(0).to_s
def mod4(n)
  ("abc".each_char { |x| next if x == "b"; n += 1 }) rescue n = -1
  n
end
puts "each_char modifier value: " + mod4(0).to_s
def mod5(n)
  ("abc".each_byte { |x| next if x == 98; n += 1 }) rescue n = -1
  n
end
puts "each_byte modifier value: " + mod5(0).to_s
def mod6(n)
  ("abc".each_grapheme_cluster { |x| next if x == "b"; n += 1 }) rescue n = -1
  n
end
puts "each_grapheme_cluster modifier value: " + mod6(0).to_s
def mod7(n)
  ("abc".each_codepoint { |x| next if x == 98; n += 1 }) rescue n = -1
  n
end
puts "each_codepoint modifier value: " + mod7(0).to_s
def mod8(n)
  ([1, 2, 3].each_index { |x| next if x == 1; n += 1 }) rescue n = -1
  n
end
puts "each_index modifier value: " + mod8(0).to_s
def mod9(n)
  (Array.new(3) { |x| next 0 if x == 1; n += 1 }) rescue n = -1
  n
end
puts "Array.new modifier value: " + mod9(0).to_s
def mod10(n)
  ("abc".chars { |x| next if x == "b"; n += 1 }) rescue n = -1
  n
end
puts "chars modifier value: " + mod10(0).to_s
def mod11(n)
  ("abc".bytes { |x| next if x == 98; n += 1 }) rescue n = -1
  n
end
puts "bytes modifier value: " + mod11(0).to_s
def mod12(n)
  ("abc".codepoints { |x| next if x == 98; n += 1 }) rescue n = -1
  n
end
puts "codepoints modifier value: " + mod12(0).to_s
def mod13(n)
  ({ "a" => [1, 2, 3], "n" => 1 }["a"].each_index { |x| next if x == 1; n += 1 }) rescue n = -1
  n
end
puts "boxed each_index modifier value: " + mod13(0).to_s
def mod14(n)
  (["a", "b", "c"].each_index { |x| next if x == 1; n += 1 }) rescue n = -1
  n
end
puts "String each_index modifier value: " + mod14(0).to_s
def mod15(n)
  ([1, "a", nil].each_index { |x| next if x == 1; n += 1 }) rescue n = -1
  n
end
puts "mixed each_index modifier value: " + mod15(0).to_s

# a `next v` there is not the value of the block around the loop
p [1, 2].map { |x| "ab".each_char { |c| next "q" if c == "a" }; x }
p [1, 2].map { |x| [5, 6].each_index { |i| next "q" if i == 0 }; x }
p ["a", "b"].map { |x| "ab".each_line { |l| next 1 if l == "a" }; x }

# the same loops reached through an Enumerator, and a scan as a value in
# Array.new's block
n = 0
begin; "abc".each_char.each { |x| next if x == "b"; n += 1 }; raise "late"; rescue => e; puts "each_char.each: " + n.to_s + " " + e.message; end
pe = proc { |s| m = 0; s.each_char.each { |x| next if x == "b"; m += 1 }; m }
puts "each_char.each in a proc: " + pe.call("abc").to_s
begin
  p Array.new(2) { |i| r = "ab".scan(/./) { |m| next if m == "a" }; next 9 if i == 1; r.size }
  raise "late"
rescue => e
  puts "scan in Array.new: " + e.message
end

# inside another loop's turn
n = 0
2.times do
  begin
    "a\nbb\nc".each_line { |x| next if x.size > 2; n += 1 }
    raise "late"
  rescue => e
    n += 10
  end
end
puts n

# the frames are all gone: a raise with no rescue of the loops above
begin
  raise "x"
rescue => e
  puts "rescued " + e.message
end

# the iterators that had it right stay right
n = 0
begin; "abc".bytes.each { |x| next if x == 98; n += 1 }; raise "late"; rescue => e; puts "6: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".chars.each { |x| next if x == "b"; n += 1 }; raise "late"; rescue => e; puts "7: " + n.to_s + " " + e.message; end
n = 0
begin; "a1b2".scan(/\d/) { |x| next if x == "1"; n += 1 }; raise "late"; rescue => e; puts "10: " + n.to_s + " " + e.message; end
n = 0
begin; "a1b2".gsub(/\d/) { |x| next "" if x == "1"; n += 1; "" }; raise "late"; rescue => e; puts "11: " + n.to_s + " " + e.message; end
n = 0
begin; "a b".split(" ").each { |x| next if x == "a"; n += 1 }; raise "late"; rescue => e; puts "12: " + n.to_s + " " + e.message; end
n = 0
begin; "a".upto("c") { |x| next if x == "b"; n += 1 }; raise "late"; rescue => e; puts "13: " + n.to_s + " " + e.message; end
n = 0
begin; 3.times { |x| next if x == 1; n += 1 }; raise "late"; rescue => e; puts "14: " + n.to_s + " " + e.message; end
n = 0
begin; 1.upto(3) { |x| next if x == 2; n += 1 }; raise "late"; rescue => e; puts "15: " + n.to_s + " " + e.message; end
n = 0
begin; 3.downto(1) { |x| next if x == 2; n += 1 }; raise "late"; rescue => e; puts "16: " + n.to_s + " " + e.message; end
n = 0
begin; 1.step(5, 2) { |x| next if x == 3; n += 1 }; raise "late"; rescue => e; puts "17: " + n.to_s + " " + e.message; end
n = 0
begin; (1..3).each { |x| next if x == 2; n += 1 }; raise "late"; rescue => e; puts "18: " + n.to_s + " " + e.message; end
n = 0
begin; (1..3).each_with_index { |x, i| next if x == 2; n += 1 }; raise "late"; rescue => e; puts "19: " + n.to_s + " " + e.message; end
n = 0
begin; (1...6).step(2) { |x| next if x == 3; n += 1 }; raise "late"; rescue => e; puts "20: " + n.to_s + " " + e.message; end
n = 0
begin; ("a".."c").each { |x| next if x == "b"; n += 1 }; raise "late"; rescue => e; puts "21: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].each { |x| next if x == 2; n += 1 }; raise "late"; rescue => e; puts "22: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].each_with_index { |x, i| next if x == 2; n += 1 }; raise "late"; rescue => e; puts "23: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].reverse_each { |x| next if x == 2; n += 1 }; raise "late"; rescue => e; puts "24: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].map { |x| next 0 if x == 2; n += 1 }; raise "late"; rescue => e; puts "26: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].select { |x| next false if x == 2; n += 1 }; raise "late"; rescue => e; puts "27: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].each_slice(2) { |x| next if x.size == 1; n += 1 }; raise "late"; rescue => e; puts "28: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].each_cons(2) { |x| next if x[0] == 1; n += 1 }; raise "late"; rescue => e; puts "29: " + n.to_s + " " + e.message; end
n = 0
begin; [1, "a", nil].each { |x| next if x == "a"; n += 1 }; raise "late"; rescue => e; puts "30: " + n.to_s + " " + e.message; end
n = 0
begin; ["a", "b"].each { |x| next if x == "a"; n += 1 }; raise "late"; rescue => e; puts "31: " + n.to_s + " " + e.message; end
n = 0
begin; [1.5, 2.5].each { |x| next if x > 2; n += 1 }; raise "late"; rescue => e; puts "32: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].cycle(2) { |x| next if x == 2; n += 1 }; raise "late"; rescue => e; puts "33: " + n.to_s + " " + e.message; end
n = 0
begin; [3, 1, 2].sort_by { |x| next 0 if x == 2; n += 1; x }; raise "late"; rescue => e; puts "34: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].inject(0) { |a, x| next a if x == 2; n += 1; a + x }; raise "late"; rescue => e; puts "35: " + n.to_s + " " + e.message; end
n = 0
begin; { "a" => 1, "b" => 2 }.each { |k, v| next if v == 1; n += 1 }; raise "late"; rescue => e; puts "36: " + n.to_s + " " + e.message; end
n = 0
begin; { "a" => 1, "b" => 2 }.each_key { |k| next if k == "a"; n += 1 }; raise "late"; rescue => e; puts "37: " + n.to_s + " " + e.message; end
n = 0
begin; { "a" => 1, "b" => 2 }.each_value { |v| next if v == 1; n += 1 }; raise "late"; rescue => e; puts "38: " + n.to_s + " " + e.message; end
n = 0
begin; { a: 1, b: 2 }.each_pair { |k, v| next if v == 1; n += 1 }; raise "late"; rescue => e; puts "39: " + n.to_s + " " + e.message; end
n = 0
begin; { 1 => "a", 2 => "b" }.each { |k, v| next if k == 1; n += 1 }; raise "late"; rescue => e; puts "40: " + n.to_s + " " + e.message; end
n = 0
begin
  loop { n += 1; break if n > 2; next }
  raise "late"
rescue => e
  puts "41: " + n.to_s + " " + e.message
end
n = 0
begin
  i = 0; while i < 3; i += 1; next if i == 2; n += 1; end
  raise "late"
rescue => e
  puts "42: " + n.to_s + " " + e.message
end
n = 0
begin
  i = 0; until i >= 3; i += 1; next if i == 2; n += 1; end
  raise "late"
rescue => e
  puts "43: " + n.to_s + " " + e.message
end
n = 0
begin
  for x in [1, 2, 3]; next if x == 2; n += 1; end
  raise "late"
rescue => e
  puts "44: " + n.to_s + " " + e.message
end
n = 0
begin
  for x in 1..3; next if x == 2; n += 1; end
  raise "late"
rescue => e
  puts "45: " + n.to_s + " " + e.message
end
n = 0
begin; 5.step(1, -2) { |x| next if x == 3; n += 1 }; raise "late"; rescue => e; puts "46: " + n.to_s + " " + e.message; end
n = 0
begin; 1.0.step(2.0, 0.5) { |x| next if x == 1.5; n += 1 }; raise "late"; rescue => e; puts "47: " + n.to_s + " " + e.message; end
n = 0
begin; 3.times.each { |x| next if x == 1; n += 1 }; raise "late"; rescue => e; puts "49: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].each_entry { |x| next if x == 2; n += 1 }; raise "late"; rescue => e; puts "50: " + n.to_s + " " + e.message; end
n = 0
begin; "a\nbb".each_line.each { |x| next if x.size > 2; n += 1 }; raise "late"; rescue => e; puts "51: " + n.to_s + " " + e.message; end
n = 0
begin; [[1, 2], [3, 4]].each { |a, b| next if a == 1; n += 1 }; raise "late"; rescue => e; puts "52: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].each_with_object([]) { |x, acc| next if x == 2; n += 1 }; raise "late"; rescue => e; puts "53: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].filter_map { |x| next if x == 2; n += 1 }; raise "late"; rescue => e; puts "54: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].flat_map { |x| next [] if x == 2; n += 1; [x] }; raise "late"; rescue => e; puts "55: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].find { |x| next false if x == 2; n += 1; false }; raise "late"; rescue => e; puts "56: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].any? { |x| next false if x == 2; n += 1; false }; raise "late"; rescue => e; puts "57: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].count { |x| next false if x == 2; n += 1; true }; raise "late"; rescue => e; puts "58: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].sum { |x| next 0 if x == 2; n += 1; x }; raise "late"; rescue => e; puts "59: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].each_with_index.map { |x, i| next 0 if x == 2; n += 1 }; raise "late"; rescue => e; puts "60: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].delete_if { |x| next false if x == 2; n += 1; false }; raise "late"; rescue => e; puts "61: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].partition { |x| next false if x == 2; n += 1; true }; raise "late"; rescue => e; puts "62: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].group_by { |x| next 0 if x == 2; n += 1; x }; raise "late"; rescue => e; puts "63: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].min_by { |x| next 0 if x == 2; n += 1; x }; raise "late"; rescue => e; puts "64: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].zip([4, 5, 6]) { |a, b| next if a == 2; n += 1 }; raise "late"; rescue => e; puts "65: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2, 3].take_while { |x| next true if x == 2; n += 1; true }; raise "late"; rescue => e; puts "66: " + n.to_s + " " + e.message; end
n = 0
begin; { "a" => 1 }.map { |k, v| next 0 if v == 2; n += 1 }; raise "late"; rescue => e; puts "67: " + n.to_s + " " + e.message; end
n = 0
begin; { "a" => 1, "b" => 2 }.select { |k, v| next false if v == 1; n += 1; true }; raise "late"; rescue => e; puts "68: " + n.to_s + " " + e.message; end
n = 0
begin; { "a" => 1, "b" => 2 }.each_with_index { |kv, i| next if i == 0; n += 1 }; raise "late"; rescue => e; puts "69: " + n.to_s + " " + e.message; end
n = 0
begin; (1..3).map { |x| next 0 if x == 2; n += 1 }; raise "late"; rescue => e; puts "70: " + n.to_s + " " + e.message; end
n = 0
begin; (1..3).select { |x| next false if x == 2; n += 1 }; raise "late"; rescue => e; puts "71: " + n.to_s + " " + e.message; end
n = 0
begin; (1..3).reverse_each { |x| next if x == 2; n += 1 }; raise "late"; rescue => e; puts "72: " + n.to_s + " " + e.message; end
n = 0
begin; 1.upto(3).each { |x| next if x == 2; n += 1 }; raise "late"; rescue => e; puts "73: " + n.to_s + " " + e.message; end
n = 0
begin; "abc".each_char.with_index { |x, i| next if i == 1; n += 1 }; raise "late"; rescue => e; puts "74: " + n.to_s + " " + e.message; end

# a next under a rescue modifier inside the block: the modifier's frame
# is not one the loop counts, so such a block is not recorded, and these
# print what they did
begin; "a\nb\n".each_line { |x| next if x == "a\n" rescue print "r"; print "t" }; print "z"; raise "late"; rescue => e; puts " " + e.message + ": each_line, next under a modifier"; end
begin; "a\nb\n".lines { |x| next if x == "a\n" rescue print "r"; print "t" }; print "z"; raise "late"; rescue => e; puts " " + e.message + ": lines, next under a modifier"; end
begin; "ab".each_char { |x| next if x == "a" rescue print "r"; print "t" }; print "z"; raise "late"; rescue => e; puts " " + e.message + ": each_char, next under a modifier"; end
begin; "ab".chars { |x| next if x == "a" rescue print "r"; print "t" }; print "z"; raise "late"; rescue => e; puts " " + e.message + ": chars, next under a modifier"; end
begin; "ab".each_byte { |x| next if x == 97 rescue print "r"; print "t" }; print "z"; raise "late"; rescue => e; puts " " + e.message + ": each_byte, next under a modifier"; end
begin; "ab".bytes { |x| next if x == 97 rescue print "r"; print "t" }; print "z"; raise "late"; rescue => e; puts " " + e.message + ": bytes, next under a modifier"; end
begin; "ab".each_codepoint { |x| next if x == 97 rescue print "r"; print "t" }; print "z"; raise "late"; rescue => e; puts " " + e.message + ": each_codepoint, next under a modifier"; end
begin; "ab".each_grapheme_cluster { |x| next if x == "a" rescue print "r"; print "t" }; print "z"; raise "late"; rescue => e; puts " " + e.message + ": each_grapheme_cluster, next under a modifier"; end
begin; [7, 8].each_index { |x| next if x == 0 rescue print "r"; print "t" }; print "z"; raise "late"; rescue => e; puts " " + e.message + ": each_index, next under a modifier"; end
begin; q = Array.new(2) { |x| next if x == 0 rescue print "r"; print "t"; 7 }; print q.inspect; raise "late"; rescue => e; puts " " + e.message + ": Array.new, next under a modifier"; end
begin; q = Array.new(2) { |x| (next 5 if x == 0) rescue 0; print "t"; 7 }; print q.inspect; raise "late"; rescue => e; puts " " + e.message + ": Array.new, next with a value under a modifier"; end
begin; "ab".each_char { |x| v = (next if x == "a") rescue 0; print "t" }; print "z"; raise "late"; rescue => e; puts " " + e.message + ": each_char, next as a value"; end
begin; "ab".each_char { |x| (begin; next if x == "a"; rescue; print "x"; end) rescue print "r"; print "t" }; print "z"; raise "late"; rescue => e; puts " " + e.message + ": each_char, next in a begin under a modifier"; end
begin; "ab".each_char { |x| (begin; begin; next if x == "a"; rescue; print "x"; end; rescue; print "y"; end) rescue print "r"; print "t" }; print "z"; raise "late"; rescue => e; puts " " + e.message + ": each_char, next in two begins under a modifier"; end
begin; "ab".each_char { |x| (begin; raise "i" if x == "a"; rescue; next; end) rescue print "r"; print "t" }; print "z"; raise "late"; rescue => e; puts " " + e.message + ": each_char, next in a rescue clause under a modifier"; end
begin; "ab".each_char { |x| (begin; print "e"; ensure; print "n"; end; next if x == "a") rescue print "r"; print "t" }; print "z"; raise "late"; rescue => e; puts " " + e.message + ": each_char, next after an ensure under a modifier"; end
begin; "ab".each_char { |x| begin; print "e"; ensure; next if x == "a"; end rescue print "r"; print "t" }; print "z"; raise "late"; rescue => e; puts " " + e.message + ": each_char, next in an ensure clause under a modifier"; end
begin; "ab".each_char { |x| next if x == "a" rescue print "r"; (raise "i" if !(x == "a")) rescue print "R"; print "t" }; print "z"; raise "late"; rescue => e; puts " " + e.message + ": each_char, next and a raise under a second modifier"; end
