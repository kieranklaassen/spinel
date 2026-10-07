# A superclass written as a path whose last name is a builtin exception's
# and which names a class of the program: what respond_to? answers is left
# as it was.
module App; end
class App::KeyError
  def hi = 1
end
class App::MyErr < App::KeyError; end
e = App::MyErr.new
p e.respond_to?(:message)
p e.respond_to?(:hi)
