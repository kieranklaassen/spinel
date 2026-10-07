# Array#pack with an element that is a boxed String the program has appended
# to: the element is a String, so its bytes are packed (it packed as empty).
h = { "k" => +"a", "n" => 1 }
h["k"] << "b"
p [h["k"]].pack("a*"), [h["k"], 1].pack("A3C"), [h["k"]].pack("Z*")
p [h["k"]].pack("m"), [h["k"]].pack("M"), [h["k"]].pack("u")
p [h["k"]].pack("H*"), [h["k"]].pack("b*")
p [1, h["k"], "zz"].pack("Ca2a2")

a = [+"4a", 2]
a[0] << "6f"
p [a[0]].pack("H*"), [a[0], a[0]].pack("a2a*")

# every byte is packed, a NUL too
h["k"] << "\0c"
p [h["k"]].pack("a*").bytesize, [h["k"]].pack("m")

# an empty one
e = { "k" => +"", "n" => 1 }
e["k"] << ""
p [e["k"]].pack("a*"), [e["k"]].pack("a2"), [e["k"]].pack("m")

# where an Integer is wanted it is named a String
begin
  [h["k"]].pack("C")
rescue TypeError => err
  puts err.message
end
