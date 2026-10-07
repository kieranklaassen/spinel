# A constant that is another name for a class, under the name of an
# exception class of the program: what respond_to? answers is left as it was.
class Plain
  def hi = 1
end
module A
  MyErr = Plain
  def self.make = MyErr.new
end
class MyErr < StandardError; end
p A.make.respond_to?(:message)
