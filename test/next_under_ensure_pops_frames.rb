# A `next` under an ensure leaves the begin/rescue frames opened around
# that ensure inside the loop body. Left on the stack, the frame of a turn
# that is over catches the next raise: its rescue clause runs again, and
# what follows the loop runs twice.

# the ensure in a begin/rescue: the raise after the loop is the outer one's
begin
  ["a", "b"].each { |c|
    begin
      begin
        next if c == "a"
      ensure
        print "e"
      end
    rescue
      print "r"
    end
  }
  raise "late"
rescue => ex
  puts ex.message
end

# in a method, with a statement after the loop that must run once
def after_once(xs)
  n = 0
  begin
    xs.each { |x|
      begin
        begin
          next if x == 2
          n += x
        ensure
          n += 10
        end
      rescue
        n += 1000
      end
    }
    print "after "
    raise "late"
  rescue => e
    print e.message, " "
  end
  n
end
p after_once([1, 2, 3])

# two frames around the ensure
t = 0
begin
  [1, 2, 3].each { |x|
    begin
      begin
        begin
          next if x == 2
        ensure
          t += 1
        end
      rescue
        t += 100
      end
    rescue
      t += 1000
    end
  }
  raise "two"
rescue => e
  print e.message, " "
end
p t

# an ensure, a begin/rescue, an ensure: the inner one chains to the outer
t = 0
begin
  [1, 2, 3].each { |x|
    begin
      begin
        begin
          next if x == 2
        ensure
          t += 1
        end
      rescue
        t += 100
      end
    ensure
      t += 10
    end
  }
  raise "chain"
rescue => e
  print e.message, " "
end
p t

# the ensure in the rescue clause of a begin that stands in another
t = 0
begin
  [1, 2, 3].each { |x|
    begin
      begin
        raise "q"
      rescue
        begin
          next if x == 2
        ensure
          t += 1
        end
      end
    rescue
      t += 100
    end
  }
  raise "clause"
rescue => e
  print e.message, " "
end
p t

# while, for, a Range, upto and a Hash
t = 0
begin
  i = 0
  while i < 3
    i += 1
    begin
      begin
        next if i == 2
      ensure
        t += 1
      end
    rescue
      t += 100
    end
  end
  for x in [1, 2, 3]
    begin
      begin
        next if x == 2
      ensure
        t += 1
      end
    rescue
      t += 100
    end
  end
  (1..3).each { |x|
    begin
      begin
        next if x == 2
      ensure
        t += 1
      end
    rescue
      t += 100
    end
  }
  1.upto(3) { |x|
    begin
      begin
        next if x == 2
      ensure
        t += 1
      end
    rescue
      t += 100
    end
  }
  { 1 => 0, 2 => 0, 3 => 0 }.each { |x, v|
    begin
      begin
        next if x == 2
      ensure
        t += 1
      end
    rescue
      t += 100
    end
  }
  raise "five"
rescue => e
  print e.message, " "
end
p t

# a next with a value, a break and a raise beside the next (right before)
t = 0
begin
  [1, 2, 3, 4].each { |x|
    begin
      begin
        next 7 if x == 1
        break if x == 3
        raise "in" if x == 2
      ensure
        t += 1
      end
    rescue
      t += 100
    end
  }
  raise "beside"
rescue => e
  print e.message, " "
end
p t

# two hundred turns: every frame is popped, so the stack does not fill
t = 0
200.times { |i|
  begin
    begin
      next if i.even?
    ensure
      t += 1
    end
  rescue
    t += 100
  end
}
p t
