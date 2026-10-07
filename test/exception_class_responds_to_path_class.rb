# A class written as a path that shares its last name with an exception
# class of the program: what respond_to? answers is left as it was.
class MyErr < StandardError; end
module A; end
class A::MyErr
  def hi = 1
end
e = A::MyErr.new
p e.respond_to?(:message)
puts(e.respond_to?(:message) ? "has" : "no")
