# A String local the program appends to is held as a handle. A builtin call
# that answers nil -- gets at the end of the input, a group that took no
# part in a match, a bang method that changed nothing -- leaves that handle
# NULL, and the nil test the program makes before it appends reads it as nil.

def next_line
  line = gets
  return "end of input" if line.nil?
  line << "!"
  line << "?"
  line
end
puts next_line

def stdin_line
  t = STDIN.gets
  return t.to_s if t.nil?
  t << "a"
  t << "b"
  t
end
p stdin_line

def stdin_bytes
  t = STDIN.read(3)
  return "[#{t}]" if t.nil?
  t << "a"
  t << "b"
  t
end
p stdin_bytes

def stdin_char
  t = STDIN.getc
  return t if t.nil?
  t << "a"
  t << "b"
  t
end
p stdin_char

def group(s)
  m = s.match(/(x)?b/)
  t = m[1]
  return t if t.nil?
  t << "a"
  t << "b"
  t
end
p group("ab")
p group("xb")

def last_group(s)
  s =~ /(x)?b/
  t = Regexp.last_match(1)
  return t if t.nil?
  t << "a"
  t << "b"
  t
end
p last_group("ab")
p last_group("xb")

def chomped(s)
  t = s.chomp!
  return t if t.nil?
  t << "a"
  t << "b"
  t
end
p chomped(+"line")
p chomped(+"line\n")

def replaced(s)
  t = s.sub!("x", "y")
  return t if t.nil?
  t << "a"
  t << "b"
  t
end
p replaced(+"ab")
p replaced(+"xb")

def searched(a, k)
  t = a.bsearch { |x| x >= k }
  return t if t.nil?
  t << "a"
  t << "b"
  t
end
p searched(["a", "b"], "z")
p searched([+"a", +"b"], "b")
