# A changed copy stored back is the cure for `[]=`, but an assignment
# under a String or Regexp index does nothing to a String that is then
# stored, so the refusal prints no rewrite for it.
X = [+"q1", +"r"]
X.find { |s| s.start_with?("q") }["q"] = "Z"
p X
