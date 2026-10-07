# A bare `message` in a method of a program's own exception class is the
# exception's message, as `self.message` is. With no receiver it was a
# NameError when the method ran:
#
#   class ValErr < StandardError
#     def shout = message.upcase   # undefined local variable or method 'message'
#   end
class ValErr < StandardError
  attr_reader :field
  def initialize(field, msg = "is invalid")
    @field = field
    super(msg)
    @size = message.size
  end
  def shout = message.upcase
  def describe = "[#{field}] #{message}"
  def pairs = [[:field, field], [:message, message]]
  def same? = message == self.message
  def size_was = @size
  def later
    x = message            # still the call: the local is assigned after it
    message = "local"
    x + "/" + message
  end
  # these two were not the NameError: they answered nil and 0
  def total = message.bytes.sum
  def memo
    @memo ||= message
    @memo
  end
end

begin
  raise ValErr.new(:name)
rescue ValErr => e
  p e.shout, e.describe, e.pairs, e.same?, e.size_was, e.later
  p e.total, e.memo
end

# under other parents, with the default message, and never raised
class Quiet < RuntimeError
  def brief = "q: " + message
end
p Quiet.new.brief, Quiet.new("x").brief

class BadArg < ArgumentError
  def brief = message.length
end
begin
  raise BadArg, "four"
rescue BadArg => e
  p e.brief
end

# a method of the parent class, run on an instance of the subclass
class Base < StandardError
  def tag = "<" + message + ">"
end
class Leaf < Base
end
begin
  raise Leaf, "leaf"
rescue Base => e
  p e.tag
end

# the class's own #to_s is what #message answers
class Coded < StandardError
  def to_s = "coded: " + super
  def loud = message.upcase
end
p Coded.new("m").loud

# a method a module brings in
module Describable
  def summary = "summary: " + message
end
class Mixed < StandardError
  include Describable
end
p Mixed.new("mixed").summary

# the class's own method or reader of that name binds first
class Own < StandardError
  def message = "own"
  def show = message
end
class Read < StandardError
  attr_reader :message
  def initialize(m)
    super("base")
    @message = m
  end
  def show = message
end
p Own.new("x").show, Read.new("mine").show
