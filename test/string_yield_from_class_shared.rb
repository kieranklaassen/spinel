# A top-level method that yields its parameter, called from inside a class
# or a module: the calls that share the caller's String build as they do
# at top level, and the append reaches it.
def app(s) = yield(s)
def twice(s, &b) = b.call(s) + b.call(s)

class Holder
  def initialize = @s = +"i"

  def go(prm)
    s = +"l"
    app(s) { |k| k << "!" }
    app(@s) { |k| k << "!" }
    app(prm) { |k| k << "!" }
    p s, @s, prm
    pr = proc { |k| k.size }
    p twice(s, &pr)
    $g = +"g"
    p twice($g, &pr)
  end

  def self.go
    s = +"c"
    app(s) { |k| k << "!" }
    p s
  end
end
Holder.new.go(+"p")
Holder.go

module Tools
  def self.go
    s = +"m"
    app(s) { |k| k << "?" }
    1.times { app(s) { |k| k << "!" } }
    p s
  end
end
Tools.go
