# An ensure body is ordinary code: every statement in it runs, also while a
# throw, a break or a proc's return is on its way out through it, and
# whatever the body does next (a return, a raise, another throw) takes over
# from there.
def log(s)
  begin
    print s
  ensure
    print "."
  end
end

def guard
  yield
ensure
  print "g "
end

# an ensure of its own inside the body, under a throw, a break, a return
def thrown
  catch(:x) do
    begin
      throw :x, 7
    ensure
      begin
        print "a "
      ensure
        print "b "
      end
      print "c "
    end
  end
end
p thrown

def broken
  [1, 2].each do |v|
    begin
      break
    ensure
      begin
        print "a "
      ensure
        print "b "
      end
      print "c "
    end
  end
  :after
end
p broken

def returned
  pr = proc do
    begin
      return 5
    ensure
      begin
        print "a "
      ensure
        print "b "
      end
      print "c "
    end
  end
  pr.call
  :not_here
end
p returned

# a method with an ensure of its own, called from the body
def called
  catch(:x) do
    begin
      throw :x, 8
    ensure
      log("a")
      log("b")
      print " c "
    end
  end
end
p called

# two levels, and through two methods
def deep
  [1, 2, 3].each do |v|
    begin
      begin
        break v * 10
      ensure
        log("in")
        print " c1 "
      end
    ensure
      log("out")
      print " c2 "
    end
  end
end
p deep

def inner_m
  begin
    throw :x, 4
  ensure
    log("i")
    print "c1 "
  end
end

def outer_m
  begin
    inner_m
  ensure
    log("o")
    print "c2 "
  end
end
p catch(:x) { outer_m }

# a method's own ensure, a block's own ensure, a block method in the body
def def_ensure
  throw :x, 5
ensure
  log("d")
  print "c "
end
p catch(:x) { def_ensure }

r = catch(:x) do
  [1].each do |v|
    throw :x, 6
  ensure
    log("b")
    print "c "
  end
end
p r

def blk_in_ensure
  catch(:x) do
    begin
      throw :x, 7
    ensure
      guard { print "y " }
      print "c "
    end
  end
end
p blk_in_ensure

# code of the program the body runs without a call written in it: an
# interpolation, an operator of an object
class Noisy
  def to_s
    begin
      "noisy"
    ensure
      print "."
    end
  end

  def ==(other)
    begin
      true
    ensure
      print "="
    end
  end
end
$o = Noisy.new
$s = nil
$t = 0
def interpolated
  catch(:x) do
    begin
      throw :x, 1
    ensure
      $s = "#{$o}"
      $t += 1
    end
  end
end
p interpolated, $s, $t

def compared
  catch(:x) do
    begin
      throw :x, 2
    ensure
      $s = ($o == 3)
      $t += 1
    end
  end
end
p compared, $s, $t

# what the body does next takes over
def ret_over
  catch(:x) do
    begin
      throw :x, 1
    ensure
      log("a")
      return 5
    end
  end
  :not_here
end
p ret_over

def exc_over
  catch(:x) do
    begin
      throw :x, 1
    ensure
      log("a")
      raise ArgumentError, "over"
    end
  end
rescue => e
  e.message
end
p exc_over

def again
  catch(:x) do
    begin
      throw :x, 1
    ensure
      log("a")
      throw :x, 9
    end
  end
end
p again

# the value thrown is kept across a catch that completes in the body
def keeps_value
  catch(:x) do
    begin
      throw :x, [1, "two"]
    ensure
      log("k")
      print catch(:y) { throw :y, "y " }
      print "c "
    end
  end
end
p keeps_value

# what was right stays right: a raise passing through, a while loop's break,
# a next, a lambda's return, a fiber resumed from the body, a body that
# runs no code of the program
def raised
  begin
    begin
      raise ArgumentError, "boom"
    ensure
      log("a")
      print "c "
    end
  rescue => e
    e.message
  end
end
p raised

def while_break
  i = 0
  while true
    begin
      i += 1
      break if i == 2
    ensure
      log("w")
      print "c "
    end
  end
  i
end
p while_break

def next_block
  [1, 2].map do |v|
    begin
      next v * 2
    ensure
      log("n")
      print "c "
    end
  end
end
p next_block

def lam
  l = lambda do
    begin
      return 10
    ensure
      log("l")
      print "c "
    end
  end
  l.call + 1
end
p lam

def fib_in_ensure
  f = Fiber.new { log("f"); Fiber.yield 1; log("g"); 2 }
  catch(:x) do
    begin
      throw :x, 8
    ensure
      print f.resume, f.resume, " c "
    end
  end
end
p fib_in_ensure

$n = 0
def counted(a)
  catch(:x) do
    begin
      throw :x, a
    ensure
      $n += 2
    end
  end
end
p counted(3), $n
