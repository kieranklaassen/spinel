# An OpenStruct member named i, read through a boxed value, is the member:
# Numeric#i on a boxed value stands down where ostruct is required.

require "ostruct"

row = [OpenStruct.new(i: 3), "q"]
p row[0].i
x = row[0]
p x.i
[OpenStruct.new(i: 4), OpenStruct.new(i: 5)].each { |o| p o.i }
h = {a: OpenStruct.new(i: 6), b: "q"}
p h[:a].i
c = ARGV.empty? ? OpenStruct.new(i: 7) : "s"
p c.i
p((row[1].i rescue "NoMethodError"))
