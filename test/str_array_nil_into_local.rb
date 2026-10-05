# A nil read out of an Array of Strings into a local is nil, not "".

a = ["a", "b"]
a << nil
x = a[2]
p x
p x.nil?
p x.inspect
p x == ""
p x.class
puts x ? "set" : "unset"

# stored by index
b = ["a", "b"]
b[2] = nil
y = b[2]
puts "[#{y}]"
p y.to_s
p(y || "none")
p [y]

# a String method on it raises, as on any nil
begin
  p x.size
rescue NoMethodError => e
  puts e.class
end

# the String beside it is still that String
z = a[0]
p z
p z.nil?
p z.size
