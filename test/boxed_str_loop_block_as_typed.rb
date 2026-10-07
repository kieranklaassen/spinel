# A String read out of a Hash of mixed values runs the block of its
# each_line, each_char, each_grapheme_cluster, each_byte, each_codepoint
# and scan as a String of a known type does: a local of the block is new
# in every turn, and a `next` ends one turn of that loop and nothing else.

g = { "l" => "a\nbb\nc", "k" => "a,bb,c", "c" => "abcb", "re" => /./, "n" => 1 }

# a local first set inside the block is nil again in the next turn
g["l"].each_line { |x| y ||= x; print y.inspect, " " }; puts "each_line"
g["l"].each_line(chomp: true) { |x| y ||= x; print y.inspect, " " }; puts "each_line chomp"
g["k"].each_line(",") { |x| y ||= x; print y.inspect, " " }; puts "each_line sep"
g["k"].each_line(",", chomp: true) { |x| y ||= x; print y.inspect, " " }; puts "each_line sep chomp"
g["c"].each_char { |x| y ||= x; print y.inspect, " " }; puts "each_char"
g["c"].each_grapheme_cluster { |x| y ||= x; print y.inspect, " " }; puts "each_grapheme_cluster"
g["c"].each_byte { |x| y ||= x; print y.inspect, " " }; puts "each_byte"
g["c"].each_codepoint { |x| y ||= x; print y.inspect, " " }; puts "each_codepoint"
g["c"].scan(/./) { |x| y ||= x; print y.inspect, " " }; puts "scan Regexp"
g["c"].scan("b") { |x| y ||= x; print y.inspect, " " }; puts "scan String"
g["c"].scan(g["re"]) { |x| y ||= x; print y.inspect, " " }; puts "scan boxed"

# a `next` under a begin: the raise after the loop is rescued
n = 0
begin; g["l"].each_line { |x| next if x.size > 2; n += 1 }; raise "late"; rescue => e; puts "each_line: " + n.to_s + " " + e.message; end
n = 0
begin; g["l"].each_line(chomp: true) { |x| next if x.size > 1; n += 1 }; raise "late"; rescue => e; puts "each_line chomp: " + n.to_s + " " + e.message; end
n = 0
begin; g["k"].each_line(",") { |x| next if x.size > 2; n += 1 }; raise "late"; rescue => e; puts "each_line sep: " + n.to_s + " " + e.message; end
n = 0
begin; g["k"].each_line(",", chomp: true) { |x| next if x.size > 1; n += 1 }; raise "late"; rescue => e; puts "each_line sep chomp: " + n.to_s + " " + e.message; end
n = 0
begin; g["c"].each_char { |x| next if x == "b"; n += 1 }; raise "late"; rescue => e; puts "each_char: " + n.to_s + " " + e.message; end
n = 0
begin; g["c"].each_grapheme_cluster { |x| next if x == "b"; n += 1 }; raise "late"; rescue => e; puts "each_grapheme_cluster: " + n.to_s + " " + e.message; end
n = 0
begin; g["c"].each_byte { |x| next if x == 98; n += 1 }; raise "late"; rescue => e; puts "each_byte: " + n.to_s + " " + e.message; end
n = 0
begin; g["c"].each_codepoint { |x| next if x == 98; n += 1 }; raise "late"; rescue => e; puts "each_codepoint: " + n.to_s + " " + e.message; end
n = 0
begin; g["c"].scan(/./) { |x| next if x == "b"; n += 1 }; raise "late"; rescue => e; puts "scan Regexp: " + n.to_s + " " + e.message; end
n = 0
begin; g["c"].scan("b") { |x| next if (n += 1) == 1; n += 1 }; raise "late"; rescue => e; puts "scan String: " + n.to_s + " " + e.message; end
n = 0
begin; g["c"].scan(g["re"]) { |x| next if x == "b"; n += 1 }; raise "late"; rescue => e; puts "scan boxed: " + n.to_s + " " + e.message; end

# under an ensure: it runs once, after the loop
n = 0
begin; g["l"].each_line { |x| next if x.size > 2; n += 1 }; ensure; puts "each_line ensure: " + n.to_s; end
puts n
n = 0
begin; g["l"].each_line(chomp: true) { |x| next if x.size > 1; n += 1 }; ensure; puts "each_line chomp ensure: " + n.to_s; end
puts n
n = 0
begin; g["k"].each_line(",") { |x| next if x.size > 2; n += 1 }; ensure; puts "each_line sep ensure: " + n.to_s; end
puts n
n = 0
begin; g["k"].each_line(",", chomp: true) { |x| next if x.size > 1; n += 1 }; ensure; puts "each_line sep chomp ensure: " + n.to_s; end
puts n
n = 0
begin; g["c"].each_char { |x| next if x == "b"; n += 1 }; ensure; puts "each_char ensure: " + n.to_s; end
puts n
n = 0
begin; g["c"].each_grapheme_cluster { |x| next if x == "b"; n += 1 }; ensure; puts "each_grapheme_cluster ensure: " + n.to_s; end
puts n
n = 0
begin; g["c"].each_byte { |x| next if x == 98; n += 1 }; ensure; puts "each_byte ensure: " + n.to_s; end
puts n
n = 0
begin; g["c"].each_codepoint { |x| next if x == 98; n += 1 }; ensure; puts "each_codepoint ensure: " + n.to_s; end
puts n
n = 0
begin; g["c"].scan(/./) { |x| next if x == "b"; n += 1 }; ensure; puts "scan Regexp ensure: " + n.to_s; end
puts n
n = 0
begin; g["c"].scan("b") { |x| next if (n += 1) == 1; n += 1 }; ensure; puts "scan String ensure: " + n.to_s; end
puts n
n = 0
begin; g["c"].scan(g["re"]) { |x| next if x == "b"; n += 1 }; ensure; puts "scan boxed ensure: " + n.to_s; end
puts n

# in a proc: the proc goes on after the loop
pr = proc { |g| n = 0; g["l"].each_line { |x| next if x.size > 2; n += 1 }; n + 100 }
puts "each_line proc: " + pr.call(g).to_s
pr = proc { |g| n = 0; g["l"].each_line(chomp: true) { |x| next if x.size > 1; n += 1 }; n + 100 }
puts "each_line chomp proc: " + pr.call(g).to_s
pr = proc { |g| n = 0; g["k"].each_line(",") { |x| next if x.size > 2; n += 1 }; n + 100 }
puts "each_line sep proc: " + pr.call(g).to_s
pr = proc { |g| n = 0; g["k"].each_line(",", chomp: true) { |x| next if x.size > 1; n += 1 }; n + 100 }
puts "each_line sep chomp proc: " + pr.call(g).to_s
pr = proc { |g| n = 0; g["c"].each_char { |x| next if x == "b"; n += 1 }; n + 100 }
puts "each_char proc: " + pr.call(g).to_s
pr = proc { |g| n = 0; g["c"].each_grapheme_cluster { |x| next if x == "b"; n += 1 }; n + 100 }
puts "each_grapheme_cluster proc: " + pr.call(g).to_s
pr = proc { |g| n = 0; g["c"].each_byte { |x| next if x == 98; n += 1 }; n + 100 }
puts "each_byte proc: " + pr.call(g).to_s
pr = proc { |g| n = 0; g["c"].each_codepoint { |x| next if x == 98; n += 1 }; n + 100 }
puts "each_codepoint proc: " + pr.call(g).to_s
pr = proc { |g| n = 0; g["c"].scan(/./) { |x| next if x == "b"; n += 1 }; n + 100 }
puts "scan Regexp proc: " + pr.call(g).to_s
pr = proc { |g| n = 0; g["c"].scan("b") { |x| next if (n += 1) == 1; n += 1 }; n + 100 }
puts "scan String proc: " + pr.call(g).to_s
pr = proc { |g| n = 0; g["c"].scan(g["re"]) { |x| next if x == "b"; n += 1 }; n + 100 }
puts "scan boxed proc: " + pr.call(g).to_s

# an ensure inside the block runs, and the turn is over
n = 0
g["l"].each_line { |x| begin; next if x.size > 2; n += 1; ensure; n += 10; end; n += 100 }
puts "each_line inner ensure: " + n.to_s
n = 0
g["l"].each_line(chomp: true) { |x| begin; next if x.size > 1; n += 1; ensure; n += 10; end; n += 100 }
puts "each_line chomp inner ensure: " + n.to_s
n = 0
g["k"].each_line(",") { |x| begin; next if x.size > 2; n += 1; ensure; n += 10; end; n += 100 }
puts "each_line sep inner ensure: " + n.to_s
n = 0
g["k"].each_line(",", chomp: true) { |x| begin; next if x.size > 1; n += 1; ensure; n += 10; end; n += 100 }
puts "each_line sep chomp inner ensure: " + n.to_s
n = 0
g["c"].each_char { |x| begin; next if x == "b"; n += 1; ensure; n += 10; end; n += 100 }
puts "each_char inner ensure: " + n.to_s
n = 0
g["c"].each_grapheme_cluster { |x| begin; next if x == "b"; n += 1; ensure; n += 10; end; n += 100 }
puts "each_grapheme_cluster inner ensure: " + n.to_s
n = 0
g["c"].each_byte { |x| begin; next if x == 98; n += 1; ensure; n += 10; end; n += 100 }
puts "each_byte inner ensure: " + n.to_s
n = 0
g["c"].each_codepoint { |x| begin; next if x == 98; n += 1; ensure; n += 10; end; n += 100 }
puts "each_codepoint inner ensure: " + n.to_s
n = 0
g["c"].scan(/./) { |x| begin; next if x == "b"; n += 1; ensure; n += 10; end; n += 100 }
puts "scan Regexp inner ensure: " + n.to_s
n = 0
g["c"].scan("b") { |x| begin; next if (n += 1) == 1; n += 1; ensure; n += 10; end; n += 100 }
puts "scan String inner ensure: " + n.to_s
n = 0
g["c"].scan(g["re"]) { |x| begin; next if x == "b"; n += 1; ensure; n += 10; end; n += 100 }
puts "scan boxed inner ensure: " + n.to_s

# a `break` leaves the loop, as before
n = 0
begin; g["l"].each_line { |x| break if x.size > 2; n += 1 }; raise "late"; rescue => e; puts "each_line break: " + n.to_s + " " + e.message; end
n = 0
begin; g["l"].each_line(chomp: true) { |x| break if x.size > 1; n += 1 }; raise "late"; rescue => e; puts "each_line chomp break: " + n.to_s + " " + e.message; end
n = 0
begin; g["k"].each_line(",") { |x| break if x.size > 2; n += 1 }; raise "late"; rescue => e; puts "each_line sep break: " + n.to_s + " " + e.message; end
n = 0
begin; g["k"].each_line(",", chomp: true) { |x| break if x.size > 1; n += 1 }; raise "late"; rescue => e; puts "each_line sep chomp break: " + n.to_s + " " + e.message; end
n = 0
begin; g["c"].each_char { |x| break if x == "b"; n += 1 }; raise "late"; rescue => e; puts "each_char break: " + n.to_s + " " + e.message; end
n = 0
begin; g["c"].each_grapheme_cluster { |x| break if x == "b"; n += 1 }; raise "late"; rescue => e; puts "each_grapheme_cluster break: " + n.to_s + " " + e.message; end
n = 0
begin; g["c"].each_byte { |x| break if x == 98; n += 1 }; raise "late"; rescue => e; puts "each_byte break: " + n.to_s + " " + e.message; end
n = 0
begin; g["c"].each_codepoint { |x| break if x == 98; n += 1 }; raise "late"; rescue => e; puts "each_codepoint break: " + n.to_s + " " + e.message; end
n = 0
begin; g["c"].scan(/./) { |x| break if x == "b"; n += 1 }; raise "late"; rescue => e; puts "scan Regexp break: " + n.to_s + " " + e.message; end
n = 0
begin; g["c"].scan("b") { |x| break if (n += 1) == 1; n += 1 }; raise "late"; rescue => e; puts "scan String break: " + n.to_s + " " + e.message; end
n = 0
begin; g["c"].scan(g["re"]) { |x| break if x == "b"; n += 1 }; raise "late"; rescue => e; puts "scan boxed break: " + n.to_s + " " + e.message; end
