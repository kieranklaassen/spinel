# A program that defines is_a? itself: the class test of a boxed raised
# exception is left as it was.
class MyErr < StandardError
  def is_a?(k) = false
end
e = begin; raise MyErr, "a"; rescue => x; x; end
p [e, 3].map { |v| v.is_a?(MyErr) }
