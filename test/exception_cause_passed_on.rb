# An exception that passes a rescue none of whose clauses match keeps the
# cause it was raised with.

class MyErr < StandardError; end
class Stop < Exception; end

def show(g)
  c = g.cause
  puts g.class.to_s + " cause=" + (c ? c.class.to_s + ":" + c.message : "nil")
end

def go(how)
  begin
    raise ArgumentError, "first"
  rescue ArgumentError
    case how
    when 0 then raise TypeError, "second"
    when 1 then raise TypeError.new("second")
    when 2 then raise "second"
    when 3 then raise MyErr.new("second")
    when 4 then raise TypeError, "second", cause: KeyError.new("given")
    when 5 then raise TypeError, "second", cause: nil
    else raise Stop, "second"
    end
  end
end

# one clause, a bound one, two clauses, two begins
6.times do |how|
  begin
    begin
      go(how)
    rescue IOError
      puts "io"
    end
  rescue => g
    show(g)
  end
end
begin
  begin
    go(0)
  rescue IOError => e
    puts e.message
  end
rescue => g
  show(g)
end
begin
  begin
    begin
      go(1)
    rescue IOError
      puts "io"
    rescue ZeroDivisionError, KeyError
      puts "zk"
    end
  rescue EOFError
    puts "eof"
  end
rescue => g
  show(g)
end

# through a method whose rescue does not match, and inside a block
def via(how)
  go(how)
rescue IOError
  puts "io"
end
begin
  via(2)
rescue => g
  show(g)
end
begin
  [1].each do |_|
    begin
      go(3)
    rescue IOError
      puts "io"
    end
  end
rescue => g
  show(g)
end

# inside another handler: the cause is not that handler's exception
[0, 5].each do |how|
  begin
    begin
      raise "outer"
    rescue => o
      begin
        go(how)
      rescue IOError
        puts "io"
      end
    end
  rescue => g
    show(g)
  end
end

# a rescue modifier passes on what is no StandardError
begin
  v = (go(6) rescue 0)
  p v
rescue Exception => g
  show(g)
end
def stmt_modifier
  go(6) rescue puts("not reached")
end
begin
  stmt_modifier
rescue Exception => g
  show(g)
end

# an exception that carries a cause already keeps it, and one with none has none
def old
  begin
    raise KeyError, "k"
  rescue KeyError
    raise TypeError, "t"
  end
rescue TypeError => e
  e
end
begin
  begin
    begin
      raise "other"
    rescue => o
      raise old
    end
  rescue IOError
    puts "io"
  end
rescue => g
  show(g)
end
begin
  begin
    raise TypeError, "plain"
  rescue IOError
    puts "io"
  end
rescue => g
  show(g)
end
