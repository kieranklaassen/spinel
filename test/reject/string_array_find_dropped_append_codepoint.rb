# `<<` takes a codepoint where `+` takes only a String, so the cure for
# an Integer appended is the copy stored back, not `a[i] + x`.
a = [+"q1", +"r"]
a.find { |s| s.start_with?("q") } << 33
p a
