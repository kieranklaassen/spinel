# A change with no plain twin is cured by a copy stored back. The
# compiler refuses that store into a constant's Hash, so the refusal
# prints no rewrite there.
H = { "a" => +"q1" }
H["a"].insert(0, "x")
p H
