# A branch that stores the value into an Array of one kind, which takes no
# boxed value. The class test is left as it was and the branch is not
# reached.
class MyErr < StandardError; end
kept = [3]
begin; raise MyErr, "m"; rescue StandardError => e; kept << e; end
kept.each do |v|
  [1] << v if v.is_a?(MyErr)
end
puts "end"
