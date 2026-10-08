# equal? and eql? come to a Symbol from above it, so a method the program
# defines there under the name is the one a Symbol answers with.
class Object
  def equal?(o) = true
end
module Loose
  def eql?(o) = true
end
class Object
  include Loose
end
s = :a
p s.equal?(3)
p s.equal?("x")
p s.equal?(nil)
p s.eql?(3)
p s.eql?("x")
p s.eql?(nil)
