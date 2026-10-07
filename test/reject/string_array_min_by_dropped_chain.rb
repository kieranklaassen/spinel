# A chain's value is its last call's: dropped, every link went to the copy.
# The receiver may be in parentheses.
a = [+"q", +"r"]
(a.min_by { |s| s.size }) << "1" << "2"
p a
