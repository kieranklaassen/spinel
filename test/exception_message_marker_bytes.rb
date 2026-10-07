# An exception message is a String like any other, whatever bytes it begins
# with: here the six bytes that Spinel's own NUL-keeping message form starts
# with. The message that comes back is compared byte for byte.

MARK = "\xFF\xFECM\xFD\x01".b

def same(a, b)
  "#{a.bytesize} #{a.b == b.b}"
end

def raised(m)
  begin
    raise m
  rescue => e
    same(e.message, m)
  end
end

def raised_as(m)
  begin
    raise ArgumentError, m
  rescue ArgumentError => e
    same(e.message, m)
  end
end

def made(m)
  e = RuntimeError.new(m)
  first = same(e.message, m)
  begin
    raise e
  rescue => x
    first + " " + same(x.message, m)
  end
end

def raised_again(m)
  begin
    begin
      raise m
    rescue
      raise
    end
  rescue => e
    same(e.message, m)
  end
end

def as_cause(m)
  begin
    begin
      raise m
    rescue
      raise IOError, "second"
    end
  rescue IOError => e
    same(e.cause.message, m) + " " + e.message
  end
end

def in_callee(m)
  raise TypeError, m
end

def check(label, m)
  puts "#{label}: raised #{raised(m)}"
  puts "#{label}: raised as a class #{raised_as(m)}"
  puts "#{label}: made, then raised #{made(m)}"
  puts "#{label}: raised again #{raised_again(m)}"
  puts "#{label}: as a cause #{as_cause(m)}"
  begin
    in_callee(m)
  rescue TypeError => e
    puts "#{label}: from a callee #{same(e.message, m)}"
  end
end

# the next four bytes read as a length of a gigabyte
check("long", MARK + "AAAA rest".b)
# nothing after the six bytes, and too few for a length
check("bare", MARK)
check("short", MARK + "ab".b)
# a whole message of that form, a NUL in its length: its payload is not the message
check("whole", MARK + "\x05\x00\x00\x00hello".b)
# the same with a NUL in the payload too
check("whole, a NUL inside", MARK + "\x05\x00\x00\x00he\0lo".b)
# and with a NUL after the six bytes
check("nul", MARK + "a\0b".b)
# a whole message of that form with no NUL anywhere: each byte of its length is 1
check("large", MARK + "\x01\x01\x01\x01".b + "x" * 16_843_009)

n = 0
m = MARK + "AAAA rest".b
300.times do
  begin
    raise m
  rescue => e
    n += e.message.bytesize
  end
end
puts n
puts $!.inspect
