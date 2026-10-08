# An arm typed to a parent class builds the subclass that was raised by its
# name, at the subclass's own size: the attributes the subclass adds are nil
# until set, and what the arm sets through the parent's writer stays.
class Error < StandardError; attr_accessor :code; end
class ParseError < Error; attr_accessor :line, :ctx; end
class DeepError < ParseError; attr_accessor :a, :b, :c, :d; end

kept = []
begin
  begin
    raise ParseError, "bad"
  rescue Error => e
    e.code = 7
    raise
  end
rescue StandardError => e2
  kept << e2
end
v = kept[0]
p v.class, v.message, v.code, v.line, v.ctx

begin
  begin
    raise DeepError, "deep"
  rescue Error => e
    e.code = 9
    raise
  end
rescue StandardError => e2
  kept << e2
end
w = kept[1]
p w.class, w.message, w.code, w.line, w.ctx, w.a, w.d

begin
  begin
    raise DeepError
  rescue ParseError => e
    e.line = 3
    raise
  end
rescue StandardError => e2
  kept << e2
end
p kept[2].class, kept[2].message, kept[2].line, kept[2].b, kept[2].c

begin
  begin
    raise Error, "own"
  rescue Error => e
    e.code = 1
    raise
  end
rescue StandardError => e2
  kept << e2
end
p kept[3].class, kept[3].code
