# An exception class with a conversion CRuby calls by itself: `"a" + v` asks
# to_str, and a boxed exception is not asked. The class test is left as it
# was and the branch is not reached.
class MyErr < StandardError
  def to_str = "s"
end
kept = [3]
begin; raise MyErr, "m"; rescue StandardError => e; kept << e; end
n = 0
kept.each do |v|
  n += ("a" + v).size * 0 if v.is_a?(MyErr)
end
p n
puts "end"
