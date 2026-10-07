# A case/in subject kept by value keeps its String while it is deconstructed.
#
# A small class that is never written is kept by value: the struct lives in
# the C temp the match binds its subject to. Made in place (`case mk(i)`),
# its String is held by that temp alone, and was collected when
# #deconstruct or #deconstruct_keys allocated before it read the String:
# the pattern then bound a freed String.
#
# Each line counts the wrong matches of 3,000, one line a form: an array
# pattern, the same with classes, a case/in read for its value, `=>`, a
# pattern that names the class, a subject made by `new`, a hash pattern,
# a hash pattern that names the class, and `in` as a condition.
class Name
  def initialize(i) = @s = "#{1000 + i} " * 300

  def deconstruct
    t = "x" * 300
    u = "y" * 1500
    [@s, t, u]
  end

  def deconstruct_keys(keys)
    t = "x" * 300
    u = "y" * 1500
    { s: @s, t: t, u: u }
  end
end

def mk(i) = Name.new(i)

def bare(i, want)
  case mk(i)
  in [q, t, u]
    q == want ? 0 : 1
  else
    1
  end
end

def typed(i, want)
  case mk(i)
  in [String => q, String => t, String => u]
    q == want ? 0 : 1
  else
    1
  end
end

def value(i, want)
  x = case mk(i)
      in [q, t, u] then q == want ? 0 : 1
      else 1
      end
  x
end

def required(i, want)
  mk(i) => [q, t, u]
  q == want ? 0 : 1
end

def named(i, want)
  case mk(i)
  in Name[q, t, u]
    q == want ? 0 : 1
  else
    1
  end
end

def in_place(i, want)
  case Name.new(i)
  in [q, *rest]
    q == want ? 0 : 1
  else
    1
  end
end

def keys(i, want)
  case mk(i)
  in { s: String => q }
    q == want ? 0 : 1
  else
    1
  end
end

def named_keys(i, want)
  case mk(i)
  in Name(s: String => q)
    q == want ? 0 : 1
  else
    1
  end
end

def condition(i, want)
  if mk(i) in [q, t, u]
    q == want ? 0 : 1
  else
    1
  end
end

def wrong(which)
  bad = 0
  i = 0
  while i < 3000
    want = "#{1000 + i} " * 300
    bad += case which
           when 0 then bare(i, want)
           when 1 then typed(i, want)
           when 2 then value(i, want)
           when 3 then required(i, want)
           when 4 then named(i, want)
           when 5 then in_place(i, want)
           when 6 then keys(i, want)
           when 7 then named_keys(i, want)
           else condition(i, want)
           end
    i += 1
  end
  bad
end

puts "an array pattern: #{wrong(0)}"
puts "an array pattern with classes: #{wrong(1)}"
puts "read for its value: #{wrong(2)}"
puts "=>: #{wrong(3)}"
puts "a pattern naming the class: #{wrong(4)}"
puts "a subject made by new: #{wrong(5)}"
puts "a hash pattern: #{wrong(6)}"
puts "a hash pattern naming the class: #{wrong(7)}"
puts "in as a condition: #{wrong(8)}"
