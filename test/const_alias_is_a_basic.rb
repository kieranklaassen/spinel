# An instance of a BasicObject subclass answers no is_a?, and the class's
# body reads no constant of the program's own level: CRuby raises for both.
class Blank < BasicObject
  def blank?(v) = v.is_a?(K)
end
K = Blank
[Blank.new].each do |b|
  begin
    p b.is_a?(K)
  rescue NoMethodError
    p false
  end
end
begin
  p Blank.new.blank?(Blank.new)
rescue NameError
  p false
end
