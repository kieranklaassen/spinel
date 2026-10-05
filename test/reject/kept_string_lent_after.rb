# A String a class method keeps in a class variable's Array, then handed to a
# method that appends to it. Refused.
class Registry
  @@all = []
  def self.add(v); @@all << v; end
  def self.all = @@all
end
def stamp(t); t << "!"; end
s = +"s"
Registry.add(s)
stamp(s)
p Registry.all
