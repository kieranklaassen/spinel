# A String local the program appends to is held as a handle. A builtin call
# that answers nil -- ENV's read of a name that is not set, gets at the end
# of the input, a group that took no part in a match, a bang method that
# changed nothing -- leaves that handle NULL, and reading it is nil.

def greeting
  who = ENV["SPINEL_TEST_NO_SUCH_VARIABLE"]
  return "nobody" if who.nil?
  who << ", "
  who << "hello"
  who
end
puts greeting

def next_line
  line = gets
  return "end of input" if line.nil?
  line << "!"
  line << "?"
  line
end
puts next_line

ENV["SPINEL_TEST_SET_VARIABLE"] = "set"

def env_read(name)
  t = +""
  t << "a"
  t << "b"
  t = ENV[name]
  t
end
p env_read("SPINEL_TEST_NO_SUCH_VARIABLE")
p env_read("SPINEL_TEST_SET_VARIABLE")

def env_fetch(name)
  t = +""
  t << "a"
  t << "b"
  t = ENV.fetch(name, nil)
  t
end
p env_fetch("SPINEL_TEST_NO_SUCH_VARIABLE")
p env_fetch("SPINEL_TEST_SET_VARIABLE")

def env_delete(name)
  t = +""
  t << "a"
  t << "b"
  t = ENV.delete(name)
  t
end
p env_delete("SPINEL_TEST_NO_SUCH_VARIABLE")
p env_delete("SPINEL_TEST_SET_VARIABLE")

def stdin_line
  t = +""
  t << "a"
  t << "b"
  t = STDIN.gets
  t
end
p stdin_line

def stdin_bytes
  t = +""
  t << "a"
  t << "b"
  t = STDIN.read(3)
  t
end
p stdin_bytes

def stdin_char
  t = +""
  t << "a"
  t << "b"
  t = STDIN.getc
  t
end
p stdin_char

def group(s)
  t = +""
  t << "a"
  t << "b"
  m = s.match(/(x)?b/)
  t = m[1]
  t
end
p group("ab")
p group("xb")

def last_group(s)
  t = +""
  t << "a"
  t << "b"
  s =~ /(x)?b/
  t = Regexp.last_match(1)
  t
end
p last_group("ab")
p last_group("xb")

def chomped(s)
  t = +""
  t << "a"
  t << "b"
  t = s.chomp!
  t
end
p chomped(+"line")
p chomped(+"line\n")

def replaced(s)
  t = +""
  t << "a"
  t << "b"
  t = s.sub!("x", "y")
  t
end
p replaced(+"ab")
p replaced(+"xb")

def searched(a, k)
  t = +""
  t << "a"
  t << "b"
  t = a.bsearch { |x| x >= k }
  t
end
p searched(["a", "b"], "z")
p searched(["a", "b"], "b")
