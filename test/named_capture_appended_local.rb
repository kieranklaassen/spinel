# `/(?<w>...)/ =~ str` onto a local that is also appended to with `<<`: the
# capture is a new String each match, and the local takes it.

# a local only the capture writes (right before this change too)
def first_word(line)
  if /(?<w>[a-z]+)/ =~ line
    w << "!"
    w << "?" if w.size < 5
    w
  end
end
p first_word("  abc def"), first_word("  abcdef"), first_word("123")

# a local with a String already, appended to before and after
def over(line)
  t = +""
  t << "a"
  if /(?<t>z+)/ =~ line
    t << "!"
  else
    t = +"none"
  end
  t << "?"
  t
end
p over("azzb"), over("ab")

# two names for one String: the capture leaves the other name's String alone
def other_name
  s = +""
  t = s << "a" << "b"
  if /(?<t>z+)/ =~ "azzb"
    t << "1"
  end
  s << "!"
  [s, t]
end
p other_name

def base_name
  s = +""
  t = s << "a" << "b"
  if /(?<s>z+)/ =~ "azzb"
    s << "1"
  end
  t << "!"
  [s, t]
end
p base_name

# a name given the capture afterwards is the same String
def alias_after
  s = +""
  t = s << "a" << "b"
  /(?<t>z+)/ =~ "azzb"
  u = t
  t << "1"
  u << "2"
  [s, t, u]
end
p alias_after

# two groups, one of them appended to; in a loop; in a block; on a parameter
def two_groups
  t = +"a"
  t << "b"
  if /(?<t>z+)(?<u>b)/ =~ "azzb"
    t << u
  end
  t
end
p two_groups

def in_loop
  s = +""
  t = s << "a" << "b"
  i = 0
  while i < 2 && /(?<t>z+)/ =~ "azzb"
    t << i.to_s
    i += 1
  end
  [s, t]
end
p in_loop

def in_block
  s = +""
  t = s << "a" << "b"
  2.times do
    if /(?<t>z+)/ =~ "azzb"
      t << "!"
    end
  end
  [s, t]
end
p in_block

def on_param(t)
  t << "a"
  if /(?<t>z+)/ =~ "azzb"
    t << "!"
  end
  t
end
x = +"q"
p on_param(x), x

# the value of the match, and a group that took no part
def match_value
  s = +""
  t = s << "a" << "b"
  r = (/(?<t>z+)/ =~ "azzb")
  [r, t, s]
end
p match_value

def no_part
  s = +""
  t = s << "a" << "b"
  if /(?<t>q)?zz/ =~ "azzb"
    p t
  end
  /(?<t>q+)/ =~ "azzb"
  p t, t.nil?
  s
end
p no_part
