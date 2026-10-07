# An exit that stays inside a rescue clause leaves the clause's exception
# handled: `$!` still reads it, and a raise after it still takes it as its
# cause. The exits are a loop's break and next, a block's break, an inlined
# method's return, and each of them through an ensure. An exit that leaves a
# rescue body, a rescue modifier's fallback too, leaves its exception behind.

def d(x)
  x ? x.class.to_s + ":" + x.message : "nil"
end

def pick
  yield 1
  return 7
end

def after(tag)
  puts tag + " " + d($!)
  begin
    raise KeyError, "k"
  rescue KeyError => e
    puts "  cause " + d(e.cause)
  end
end

def in_clause(n)
  begin
    raise ArgumentError, "a" + n.to_s
  rescue ArgumentError
    case n
    when 0
      while true
        break
      end
    when 1
      i = 0
      while i < 2
        i += 1
        next
      end
    when 2 then [1, 2].each { |x| next }
    when 3 then [1, 2].each { |x| break }
    when 4 then puts [1, 2].each { |x| break x + 5 }
    when 5 then puts [1, 2, 3].find { |x| x > 1 }
    when 6 then puts pick { |x| x }
    when 7
      i = 0
      while i < 2
        i += 1
        begin
          next
        ensure
          puts "  ensure " + d($!)
        end
      end
    when 8
      [1, 2].each do |x|
        begin
          break
        ensure
          puts "  ensure " + d($!)
        end
      end
    when 9
      [1, 2].each do |x|
        begin
          raise IOError, "b"
        rescue IOError
          break
        end
      end
    when 10
      i = 0
      while i < 2
        i += 1
        raise IOError, "m" rescue next
      end
    else
      3.times { |x| next if x < 2 }
    end
    after("in " + n.to_s)
  end
  puts "left " + d($!)
end

def returned
  begin
    raise ArgumentError, "r"
  rescue ArgumentError
    begin
      return
    ensure
      puts "  ensure " + d($!)
    end
  end
end

# the clause is left: an exit to a loop around the begin
def around
  i = 0
  while i < 2
    i += 1
    begin
      raise ArgumentError, "w" + i.to_s
    rescue ArgumentError
      begin
        next if i < 2
        break
      ensure
        puts "  ensure " + d($!)
      end
    end
  end
  puts "around " + d($!)
end

def fallback_left(list)
  list.each { |x| raise IOError, "f" rescue next }
  i = 0
  while i < 2
    i += 1
    raise IOError, "g" rescue break
  end
  puts "fallback " + d($!)
end

begin
  raise TypeError, "outer"
rescue TypeError
  12.times { |n| in_clause(n) }
  returned
  around
  fallback_left([1, 2])
  puts "caller " + d($!)
end
fallback_left([1, 2])
puts "top " + d($!)
