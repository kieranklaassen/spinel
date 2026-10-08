# Left as they are: a module that reaches a class twice. Ruby keeps it once,
# where the superclass has it.
class Root
  def tag = "root"
end
module Tag
  def tag = "tag:" + super
end
module Loud
  include Tag
  def tag = super.upcase
end
class Base < Root
  include Tag
end
class Sub < Base
  include Loud
end
p Sub.new.tag
p Base.new.tag
