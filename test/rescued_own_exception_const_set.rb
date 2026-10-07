# const_set can put another class under an exception class's name: the class
# test of a boxed raised exception is left as it was.
class Other < StandardError; end
class MyErr < StandardError; end
module A
  const_set(:MyErr, Other)
  def self.chk(x) = x.is_a?(MyErr)
end
e = begin; raise MyErr, "a"; rescue => x; x; end
p [e, 3].map { |v| A.chk(v) }
