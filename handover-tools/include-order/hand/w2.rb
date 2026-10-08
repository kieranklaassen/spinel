module Shape
  def area = 0
end
class Figure
  include Shape
  def area = 1
end
class Circle < Figure
  include Shape
end
p Circle.new.area
p Circle.ancestors.first(3)
