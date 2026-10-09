# A program's own `p` may put a plain String into the Array it is handed.
# The String an element read then hands out is that one, and a change in
# place through a guarded alias of it is seen in the Array as in CRuby;
# the whole program is asked before the read is left boxed.

def p(a)
  n = a.size
  a.concat(["s#{n}"])
  nil
end

def last_changed
  r = [+"ab", 5]
  p(r)
  e = r.last
  if e.is_a?(String)
    t = e
    t << "z"
  end
  r
end

def index_changed
  r = [+"cd", 6]
  p(r)
  e = r[2]
  if e.is_a?(String)
    t = e
    t << "y"
  end
  r
end

$stdout.puts last_changed.inspect
$stdout.puts index_changed.inspect
