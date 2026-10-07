# A class's own instance_variable_get, instance_variable_set,
# instance_variable_defined?, instance_variables or
# remove_instance_variable is the method its instances answer with. A
# class with none keeps Object's.

class Record
  def initialize(n)
    @n = n
    @log = []
  end

  def instance_variable_get(name) = "get #{name} of #{@n}"

  def instance_variable_set(name, value)
    @log << [name, value]
    :stored
  end

  def instance_variable_defined?(name) = name.to_s.size
  def instance_variables = [:only, @n]
  def remove_instance_variable(name) = "remove #{name} of #{@n}"
  def log = @log

  def peek = instance_variable_get(:@n)
  def poke = instance_variable_set(:@n, 9)
  def has = instance_variable_defined?(:@n)
  def drop = remove_instance_variable(:@n)
end

class Child < Record
end

module Masked
  def instance_variable_get(name) = :masked
  def instance_variables = []
end

class Vault
  include Masked
  def initialize = @secret = 42
end

Slot = Struct.new(:a) do
  def instance_variable_get(name) = [:slot, name, a]
  def instance_variable_set(name, value) = [:slot_set, name, value]
end

class Plain
  def initialize(n) = @n = n
end

r = Record.new(3)
p r.instance_variable_get(:@n)
p r.instance_variable_get("@n")
p r.instance_variable_set(:@n, 5)
p r.instance_variable_defined?(:@n)
p r.instance_variables
p r.peek
p r.poke
p r.has
p r.log
p r&.instance_variable_get(:@zz)
p r.remove_instance_variable(:@n)
p r.drop

c = Child.new(4)
p c.instance_variable_get(:@n)
p c.instance_variables
p c.remove_instance_variable("@log")

v = Vault.new
p v.instance_variable_get(:@secret)
p v.instance_variables

s = Slot.new(1)
p s.instance_variable_get(:@a)
p s.instance_variable_set(:@b, 2)

# a class with none of its own keeps Object's
q = Plain.new(7)
p q.instance_variable_get(:@n)
p q.instance_variable_set(:@n, 8)
p q.instance_variable_get(:@n)
p q.instance_variable_defined?(:@n)
p q.instance_variable_defined?(:@zz)
p q.instance_variables
p q.remove_instance_variable(:@n)
