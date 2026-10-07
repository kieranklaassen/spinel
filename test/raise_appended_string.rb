# raise with one argument that is a boxed String the program has appended to:
# a RuntimeError with that message (it was TypeError, "exception class/object
# expected", as for a value that is no String).
h = { "k" => +"a", "n" => 1 }
h["k"] << "b"

begin
  raise h["k"]
rescue RuntimeError => e
  p e.class, e.message
end

begin
  fail h["k"]
rescue => e
  p e.class, e.message
end

def boom(v) = raise(v)
begin
  boom(h["k"])
rescue RuntimeError => e
  p e.message
end
begin
  boom([+"x", 1][0] << "y")
rescue RuntimeError => e
  p e.message
end

# the message is the text at the raise
begin
  raise h["k"]
rescue => e
  p e.message.size
end

# a value that is no String is still CRuby's TypeError
[h["n"], h["zz"]].each do |v|
  begin
    boom(v)
  rescue TypeError => e
    puts e.message
  end
end
