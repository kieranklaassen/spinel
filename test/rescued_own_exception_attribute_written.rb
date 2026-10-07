# An attribute written through a boxed value: that dispatch has no arm for
# a boxed raised exception, so the class test that guards it is left as it
# was.
class MyErr < StandardError; attr_accessor :seen; end
kept = []
begin; raise MyErr, "a"; rescue StandardError => e; kept << e; end
kept << 3
kept.each { |v| v.seen = true if v.is_a?(MyErr) }
puts "done"
