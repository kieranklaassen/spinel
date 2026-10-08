# A constant holding an exception class names it in rescue and raise.
class MyErr < StandardError; end
class CodeErr < StandardError
  def initialize(msg, code)
    super(msg)
    @code = code
  end
  def code = @code
end
module Lib
  class Err < StandardError; end
end

E = ArgumentError
ME = MyErr
CE = CodeErr
LE = Lib::Err
SE = StandardError

def try
  yield
rescue E => e
  "E #{e.class}: #{e.message}"
rescue ME, LE => e
  "ME #{e.class}: #{e.message}"
end

# a class's own constant, in its methods
class Svc
  Oops = MyErr
  def run
    raise Oops, "i"
  rescue Oops => e
    "svc #{e.class}: #{e.message}"
  end
end

# rescue
puts try { raise ArgumentError, "a" }
puts try { raise MyErr, "b" }
puts try { raise Lib::Err, "c" }
puts try { "none" }
puts Svc.new.run
begin
  raise MyErr, "d"
rescue SE => e
  puts "#{e.class}: #{e.message}"
end
begin
  raise CodeErr.new("e", 41)
rescue CE => e
  puts e.code + 1
end
begin
  begin
    raise TypeError, "f"
  rescue E, ME
    puts "wrong arm"
  end
rescue TypeError => e
  puts "outer #{e.message}"
end

# raise
begin
  raise E, "g"
rescue ArgumentError => e
  puts "#{e.class}: #{e.message}"
end
begin
  raise ME
rescue MyErr => e
  puts "#{e.class}: #{e.message}"
end
begin
  raise LE, "h"
rescue => e
  puts "#{e.class}: #{e.message}"
end
n = 0
begin
  n += 1
  raise E, "again" if n < 3
  puts "n=#{n}"
rescue E
  retry
ensure
  puts "done"
end

# a constant written twice holds what was written last
T = TypeError
T = KeyError
begin
  begin
    raise TypeError, "j"
  rescue T
    puts "wrong arm"
  end
rescue TypeError => e
  puts "outer #{e.message}"
end

# a rescue that runs before the constant is written: CRuby raises NameError
def early
  raise ArgumentError, "k"
rescue LATE
  "caught"
end
begin
  puts early
rescue StandardError
  puts "stopped"
end
LATE = ArgumentError

# a call made before the write, to a method a later body replaces
class Gate
  def fire = "none"
end
puts Gate.new.fire
AFTER = MyErr
class Gate
  def fire
    raise MyErr, "l"
  rescue AFTER
    "caught"
  rescue MyErr
    "none"
  end
end
