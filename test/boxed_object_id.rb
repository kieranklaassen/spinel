# object_id of a value held in a boxed slot. An Integer, a Symbol, nil, true
# and false have one id however they are held, so an id taken from the slot
# equals the id taken from the literal.

row = [5, "q", nil, true, false, :ab, :cd, -3]
x = row[0]
p x.object_id == 5.object_id
p x.object_id
p x.__id__
p row[2].object_id
p row[3].object_id
p row[4].object_id
p row[5].object_id == :ab.object_id
p row[6].object_id == :cd.object_id
p row[7].object_id
p x&.object_id
p x.send(:object_id)
p row.map { |v| v.is_a?(String) ? 0 : v.object_id }.first(5)

# a registry keyed by id finds the value under the literal's id
ids = {}
[5, "q", 12].each { |v| ids[v.object_id] = v }
p ids[5.object_id]
p ids[12.object_id]

# a parameter and an instance variable given two kinds
def oid(v) = v.object_id
p oid(7)
oid("s")
p oid(nil)
p oid(:cd) == :cd.object_id

class Slot
  def initialize(v) = @v = v
  def oid = @v.object_id
end
p Slot.new(9).oid
Slot.new("s").oid
p Slot.new(true).oid

# a value picked by a condition
c = ARGV.empty?
y = c ? 5 : "s"
p y.object_id
z = c ? :cd : "s"
p z.object_id == :cd.object_id

# a String keeps the one id it had
s = row[1]
p s.object_id == row[1].object_id
