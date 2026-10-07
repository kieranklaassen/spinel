# `rescue k` where k holds the class: a local, a parameter, an instance
# variable, a global, a call's answer or a constant that only names one. It
# catches what that class catches and lets the rest through.

class MyErr < ArgumentError; end
module Tagged; end
class TaggedErr < StandardError; include Tagged; end
K = ArgumentError
def klass = ArgumentError

def try(k, raised)
  begin
    raise raised, "y"
  rescue k => e
    "caught " + e.class.to_s
  end
rescue StandardError => g
  "passed on " + g.class.to_s
end

# a parameter
puts try(ArgumentError, ArgumentError)
puts try(ArgumentError, MyErr)
puts try(ArgumentError, TypeError)
puts try(StandardError, TypeError)

# a module: the classes that include it
puts try(Tagged, TaggedErr)
puts try(Tagged, TypeError)

# a class that is no exception catches nothing
puts try(String, TypeError)

# a local, beside a spelled-out class in either order
def local_first(raised)
  k = ArgumentError
  begin
    raise raised, "y"
  rescue k, IOError
    "caught"
  end
rescue StandardError => g
  "passed on " + g.class.to_s
end
def local_last(raised)
  k = ArgumentError
  begin
    raise raised, "y"
  rescue IOError, k
    "caught"
  end
rescue StandardError => g
  "passed on " + g.class.to_s
end
puts local_first(ArgumentError), local_first(IOError), local_first(TypeError)
puts local_last(ArgumentError), local_last(IOError), local_last(TypeError)

# a constant that only names the class, a call's answer, a global
def by_const(raised)
  raise raised, "y"
rescue K
  "caught by K"
rescue StandardError => g
  "passed on " + g.class.to_s
end
def by_call(raised)
  raise raised, "y"
rescue klass
  "caught by klass"
rescue StandardError => g
  "passed on " + g.class.to_s
end
$k = ArgumentError
def by_global(raised)
  raise raised, "y"
rescue $k
  "caught by $k"
rescue StandardError => g
  "passed on " + g.class.to_s
end
puts by_const(ArgumentError), by_const(TypeError)
puts by_call(MyErr), by_call(TypeError)
puts by_global(ArgumentError), by_global(TypeError)

# an instance variable, the class of an exception in hand, an element
class Guard
  def initialize(k)
    @k = k
  end
  def run(raised)
    raise raised, "y"
  rescue @k
    "caught by @k"
  rescue StandardError => g
    "passed on " + g.class.to_s
  end
end
puts Guard.new(ArgumentError).run(MyErr), Guard.new(ArgumentError).run(TypeError)
def same_class_as(seen, raised)
  raise raised, "y"
rescue seen.class
  "caught by seen.class"
rescue StandardError => g
  "passed on " + g.class.to_s
end
puts same_class_as(ArgumentError.new("x"), ArgumentError), same_class_as(ArgumentError.new("x"), TypeError)
def by_element(raised)
  ks = [ArgumentError, IOError]
  raise raised, "y"
rescue ks[0]
  "caught by ks[0]"
rescue StandardError => g
  "passed on " + g.class.to_s
end
puts by_element(ArgumentError), by_element(IOError)

# what the class lets through reaches the caller of a retry helper
def with_retry(klass)
  tries = 0
  begin
    tries += 1
    yield tries
  rescue klass
    retry if tries < 3
    "gave up"
  end
end
puts with_retry(ArgumentError) { |t| raise ArgumentError, "a" if t < 3; "ok after " + t.to_s }
puts with_retry(ArgumentError) { |t| raise ArgumentError, "a" }
begin
  puts with_retry(ArgumentError) { |t| raise TypeError, "t" if t < 3; "ok" }
rescue TypeError
  puts "TypeError reached the caller"
end

# a value that is no class or module is a TypeError
def not_a_class(pick)
  k = pick ? ArgumentError : 5
  begin
    raise ArgumentError, "y"
  rescue k
    "caught"
  end
rescue TypeError => g
  g.message
end
puts not_a_class(true), not_a_class(false)

# an Array is no class either: only `rescue *list` reads a list
LIST = [ArgumentError]
def by_list(pick)
  ks = pick ? [ArgumentError] : ArgumentError
  begin
    raise ArgumentError, "y"
  rescue ks
    "caught"
  end
rescue TypeError => g
  g.message
end
puts by_list(false), by_list(true)
begin
  begin
    raise ArgumentError, "y"
  rescue LIST
    puts "caught"
  end
rescue TypeError => g
  puts g.message
end
