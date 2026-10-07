# A constant written under the name of an exception class: inside A the
# name MyErr means Other, so the class test of a boxed raised MyErr there
# answers false and is left as it was.
class MyErr < StandardError; end
class Other < StandardError; end
module A
  MyErr = Other
  def self.mine?(x) = x.is_a?(MyErr)
  def self.kind(x) = case x when MyErr then :other else :none end
end
kept = []
begin; raise MyErr, "a"; rescue StandardError => e; kept << e; end
kept << 3
p kept.map { |v| A.mine?(v) }
p kept.map { |v| A.kind(v) }
