# A block given to the mutator is part of the change. sub! with a block,
# on a String a call takes out of an Array, changes the copy alone and
# the statement drops it: refused, not lost.
a = [+"q1", +"r"]
a.find { |s| s.start_with?("q") }.sub!("q") { |m| m * 2 }
p a
