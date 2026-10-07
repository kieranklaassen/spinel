# A class whose own `new` answers what is no instance of it: what
# respond_to? answers for an exception is left as it was.
class MyErr < StandardError
  def self.new(*) = 3
end
e = MyErr.new("q")
p e.respond_to?(:message)
