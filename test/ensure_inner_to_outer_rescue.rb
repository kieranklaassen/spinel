# An exception that leaves an inner ensure belongs to the rescue around it,
# also when that rescue and the outer ensure are clauses of one begin.

begin
  begin
    raise TypeError, "t"
  ensure
    puts "inner ensure"
  end
rescue TypeError => e
  puts "rescued " + e.message
ensure
  puts "outer ensure"
end

def in_method
  begin
    raise TypeError, "m"
  ensure
    puts "inner ensure"
  end
rescue TypeError => e
  puts "rescued " + e.message
  :rescued
ensure
  puts "outer ensure"
end
p in_method

# as a value
v = begin
  begin
    Integer("zz")
  ensure
    puts "inner ensure"
  end
rescue ArgumentError
  -1
ensure
  puts "outer ensure"
end
p v

# a clause that does not match lets it through, after both ensures
def passes
  begin
    raise IOError, "io"
  ensure
    puts "inner ensure"
  end
rescue TypeError
  puts "not reached"
ensure
  puts "outer ensure"
end
begin
  passes
rescue IOError => e
  puts "outside " + e.message
end

# three deep, the rescue in the middle
def three
  begin
    begin
      begin
        raise TypeError, "deep"
      ensure
        puts "ensure 1"
      end
    rescue TypeError => e
      puts "rescued " + e.message
    ensure
      puts "ensure 2"
    end
    puts "after"
  ensure
    puts "ensure 3"
  end
end
three

# Mutex#synchronize is such a region
def locked(m)
  m.synchronize { raise TypeError, "held" }
rescue TypeError => e
  puts "rescued " + e.message
ensure
  puts "outer ensure"
end
m = Mutex.new
locked(m)
p m.locked?

# and so is the loop of select!
def filtered(xs)
  xs.select! { |x| raise TypeError, "at " + x.to_s if x == 3; x > 1 }
rescue TypeError => e
  puts "rescued " + e.message
ensure
  puts "outer ensure"
end
xs = [1, 2, 3, 4]
filtered(xs)
p xs

# many times: no frame is left armed and none is popped twice
def quiet(log, i)
  begin
    m = Mutex.new
    m.synchronize { raise TypeError, "s" if i.odd? }
    raise TypeError, "q" if i >= 0
  ensure
    log << "i"
  end
rescue TypeError => e
  log << e.message
ensure
  log << "o"
end
log = +""
1000.times { |i| quiet(log, i) }
puts log.size
begin
  raise "late"
rescue => e
  puts e.message
end

# The clauses of the enclosing begin are asked before the exception is raised
# to them: each kind of clause, taking the exception and missing it.
class AppError < StandardError; end
class DeepError < AppError; end
module Retryable; end
class NetError < StandardError; include Retryable; end
LIST = [KeyError, IndexError]
$log = []
$m = Mutex.new

def run(tag)
  yield
  $log << "#{tag}: returned"
rescue Exception => e
  $log << "#{tag}: out #{e.class}"
end

# no clause takes it: the outer ensure runs once and it goes on
run("miss") do
  begin
    begin
      raise TypeError, "t"
    ensure
      $log << "inner"
    end
  rescue ArgumentError
    $log << "wrong clause"
  ensure
    $log << "outer"
  end
end

# the second clause takes it
run("second") do
  begin
    begin
      raise TypeError, "t"
    ensure
      $log << "inner"
    end
  rescue ArgumentError
    $log << "wrong clause"
  rescue KeyError, TypeError => e
    $log << "took #{e.class}"
  ensure
    $log << "outer"
  end
end

# a parent class takes a subclass of the program's
run("parent") do
  begin
    begin
      raise DeepError, "d"
    ensure
      $log << "inner"
    end
  rescue AppError => e
    $log << "took #{e.class}"
  ensure
    $log << "outer"
  end
end

# a bare rescue takes a StandardError and not an Exception
run("bare") do
  begin
    begin
      raise IOError, "io"
    ensure
      $log << "inner"
    end
  rescue => e
    $log << "took #{e.class}"
  ensure
    $log << "outer"
  end
end
run("bare miss") do
  begin
    begin
      raise NotImplementedError, "ni"
    ensure
      $log << "inner"
    end
  rescue => e
    $log << "took #{e.class}"
  ensure
    $log << "outer"
  end
end

# a module the class includes
run("module") do
  begin
    begin
      raise NetError, "n"
    ensure
      $log << "inner"
    end
  rescue Retryable => e
    $log << "took #{e.class}"
  ensure
    $log << "outer"
  end
end

# a splat list is not asked ahead: taken, and missed
run("splat") do
  begin
    begin
      raise IndexError, "i"
    ensure
      $log << "inner"
    end
  rescue *LIST => e
    $log << "took #{e.class}"
  ensure
    $log << "outer"
  end
end
run("splat miss") do
  begin
    begin
      raise TypeError, "t"
    ensure
      $log << "inner"
    end
  rescue *LIST => e
    $log << "took #{e.class}"
  ensure
    $log << "outer"
  end
end

# rescue Exception takes everything
run("all") do
  begin
    begin
      raise NotImplementedError, "ni"
    ensure
      $log << "inner"
    end
  rescue Exception => e
    $log << "took #{e.class}"
  ensure
    $log << "outer"
  end
end

# the inner region is a synchronize block: missed, then taken
run("sync miss") do
  begin
    $m.synchronize { raise TypeError, "t" }
  rescue ArgumentError
    $log << "wrong clause"
  ensure
    $log << "outer #{$m.locked?}"
  end
end
run("sync") do
  begin
    $m.synchronize { raise DeepError, "d" }
  rescue ArgumentError
    $log << "wrong clause"
  rescue AppError => e
    $log << "took #{e.class}"
  ensure
    $log << "outer #{$m.locked?}"
  end
end

# the inner region is select!'s loop
run("select miss") do
  a = [1, 2, 3]
  begin
    a.select! { |x| raise TypeError, "t" if x == 2; true }
  rescue ArgumentError
    $log << "wrong clause"
  ensure
    $log << "outer #{a.size}"
  end
end
run("select") do
  a = [1, 2, 3]
  begin
    a.select! { |x| raise KeyError, "k" if x == 2; true }
  rescue KeyError => e
    $log << "took #{e.class}"
  ensure
    $log << "outer #{a.size}"
  end
end

# an object with what it holds, an exception of the program's
class Coded < StandardError
  def initialize(code); super("coded"); @code = code; end
  def code; @code; end
end
run("object") do
  begin
    begin
      raise Coded.new(7)
    ensure
      $log << "inner"
    end
  rescue ArgumentError
    $log << "wrong clause"
  rescue Coded => e
    $log << "took #{e.class} #{e.code} #{e.message}"
  ensure
    $log << "outer"
  end
end
run("object miss") do
  begin
    begin
      raise Coded.new(8)
    ensure
      $log << "inner"
    end
  rescue ArgumentError
    $log << "wrong clause"
  ensure
    $log << "outer"
  end
end
puts $log
