# Raised through a variable that holds the class, rescued and kept: the
# class test answers, and the method it guards runs.
class Plain < StandardError; def note = "n"; end
class Deeper < Plain; def note = "d"; end
kept = []
[Plain, Deeper, KeyError].each { |k| begin; raise k, "a"; rescue StandardError => e; kept << e; end }
kept << Plain.new("x") << Deeper.new("y") << 3
kept.each { |v| puts v.note if v.is_a?(Plain) }
p kept.map { |v| v.instance_of?(Plain) }
