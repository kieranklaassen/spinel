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

# the inner begin has a rescue of its own that does not take it
def unmatched
  begin
    begin
      raise TypeError, "deep"
    rescue ArgumentError
      puts "not reached"
    ensure
      puts "ensure 1"
    end
  rescue TypeError => e
    puts "rescued " + e.message
  ensure
    puts "ensure 2"
  end
end
unmatched

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

# many times: no frame is left armed and none is popped twice
def quiet(log, i)
  begin
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

# Each kind of clause, taking the exception and missing it.
class AppError < StandardError; end
class DeepError < AppError; end
LIST = [KeyError, IndexError]
$log = []

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

# a splat list: taken, and missed
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

# a class that is no StandardError, named before a bare clause
run("named first") do
  begin
    begin
      raise Interrupt, "i"
    ensure
      $log << "inner"
    end
  rescue Interrupt
    $log << "named clause"
  rescue => e
    $log << "bare clause"
  ensure
    $log << "outer"
  end
end

# a raise in the clause leaves through the outer ensure, once
run("raise in the clause") do
  begin
    begin
      raise IOError, "first"
    ensure
      $log << "inner"
    end
  rescue IOError
    raise TypeError, "second"
  ensure
    $log << "outer"
  end
end

# retry runs the body again
run("retry") do
  n = 0
  begin
    begin
      n += 1
      raise IOError, "again" if n < 3
    ensure
      $log << "inner #{n}"
    end
  rescue IOError
    retry
  ensure
    $log << "outer"
  end
end

# a bare clause takes StandardError and what descends from it: not a class
# made at run time from Exception or from ScriptError
Made = Class.new(Exception)
MadeScript = Class.new(ScriptError)
run("bare, made from Exception") do
  begin
    begin
      raise Made, "made"
    ensure
      $log << "inner"
    end
  rescue => e
    $log << "rescued"
  ensure
    $log << "outer"
  end
end
run("bare second, made from ScriptError") do
  begin
    begin
      raise MadeScript, "made"
    ensure
      $log << "inner"
    end
  rescue ArgumentError
    $log << "wrong clause"
  rescue => e
    $log << "rescued"
  ensure
    $log << "outer"
  end
end

puts $log
