# A link of a String mutator chain whose argument changes the chain's
# variable in place is made on the String as the argument left it: the
# link's receiver and the variable are one object.

a = +"a-"
a.insert(0, "a").concat((a << "y"; ""))
p a

b = +"a-"
b.insert(0, "a").concat((b << "y"; "z"))
p b

c = +"a-"
c.prepend("a") << (c.upcase!; "z")
p c

d = +"a-"
d.replace("b").insert(1, (d << "y"; "z"))
p d

e = +"a-"
e.insert(0, "a").insert((e << "y"; 1), "z")
p e

f = +"a-"
f.insert(0, "a").prepend((f << "y"; "z"))
p f

# a bang as the link, and what it answers
g = +"a-"
p g.insert(0, "a").sub!("a", (g << "y"; "z"))
p g

h = +"a-"
p h.insert(0, "a").sub!("q", (h << "y"; "z"))
p h

i = +"a-"
i.insert(0, "a").sub!(/a/, (i << "y"; "z"))
p i

j = +"a-"
j.insert(0, "a").delete_suffix!((j << "y"; "y"))
p j

# a link after such a link, two arguments, and a chain inside the argument
k = +"a-"
k.insert(0, "a").concat((k << "y"; "z")).concat((k << "w"; "v"))
p k

l = +"a-"
l.insert(0, "a").concat((l << "y"; "z"), (l << "w"; "v"))
p l

m = +"a-"
m.insert(0, "a").concat((m.insert(0, "y").upcase!; "z"))
p m

n = +"a-"
n.insert(0, "a").concat((n.clear; "z"))
p n

o = +"a-"
o.insert(0, "a").concat((o << "y"; 65))
p o

# the link's value is the variable's String
q = +"a-"
p (q.insert(0, "a") << (q << "y"; "z")).size
p q

# an instance variable, a global, a parameter, a block's parameter
@r = +"a-"
@r.insert(0, "a").concat((@r << "y"; "z"))
p @r

$s = +"a-"
$s.insert(0, "a").concat(($s << "y"; "z"))
p $s

def t(u)
  u.insert(0, "a").concat((u << "y"; "z"))
  u
end
p t(+"a-")

[+"a-"].each do |v|
  v.insert(0, "a").concat((v << "y"; "z"))
  p v
end

# a variable that may be nil: its nil test is the first link's alone
y = nil
y = +"a-" if ARGV.empty?
y.insert(0, "a").sub!("a", (y << "y"; "z"))
p y

z = nil
z = +"a-" if ARGV.empty?
p z.insert(0, "a").gsub!("a", (z << "y"; "z"))
p z

# a chain that answered nil raises after the argument ran
w = +"A-"
p(begin
  w.insert(0, "A").upcase!.concat((w << "y"; "z"))
rescue NoMethodError => err
  err.class
end)
p w

# both arguments insert
v = +"a-"
p v.insert(0, "a").sub!((v.insert(0, "ya"); "a"), (v.insert(0, "ya"); "z"))
p v
