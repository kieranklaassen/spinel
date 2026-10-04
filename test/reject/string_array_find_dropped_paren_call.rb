# A parenthesized call's value is the parentheses': dropped here.
a = [+"q", +"rr"]
(a.find { |s| s.size == 2 } << "x")
p a
