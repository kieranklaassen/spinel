# message given a block, which CRuby ignores and a boxed exception's arm
# does not take. The class test is left as it was and the branch is not
# reached.
class MyErr < StandardError; end
kept = [3]
begin; raise MyErr, "m"; rescue StandardError => e; kept << e; end
n = 0
kept.each do |v|
  n += v.message { 1 }.size * 0 if v.is_a?(MyErr)
end
p n
puts "end"
