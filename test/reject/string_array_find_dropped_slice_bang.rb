# slice! answers the piece it cut and leaves the rest in the receiver, so
# the cure is not `slice` stored back: the refusal says to cut a copy and
# store the copy.
a = [+"q1", +"r"]
a.find { |s| s.start_with?("q") }.slice!(0)
p a
