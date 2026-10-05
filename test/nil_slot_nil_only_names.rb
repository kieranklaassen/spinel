# to_a, to_h, &, | and ^ on a nil held in a String or an object slot, and &,
# | and ^ on one held in a Hash slot (^ in an Array slot): nil answers them
# where the slot's class has no such method.

class Peer; end

class Card
  def name = (@name ||= +"s")
  def peer = (@peer ||= Peer.new)
  def opts = (@opts ||= {a: 1})
  def list = (@list ||= [1])
  def arg(v) = (puts "arg #{v.inspect}"; v)

  def answers
    p @name.to_a, @name.to_h, @name & arg(true), @name | arg(1), @name | arg(nil), @name ^ arg(false), @name ^ arg(:x)
    p @peer.to_a, @peer.to_h, @peer & arg(true), @peer | arg(1), @peer ^ arg(nil)
    p @opts & arg(true), @opts | arg(1), @opts ^ arg(nil), @list ^ arg(1)
    p @name.to_a.size, @peer.to_h.empty?, "#{@name.to_a}#{@peer.to_h}"
    @name.to_a
    @peer & 1
  end

  def calls
    [-> { @name.to_a }, -> { @name & arg(true) }, -> { @peer.to_h }, -> { @peer | arg(1) },
     -> { @opts ^ arg(nil) }, -> { @list ^ arg(1) }]
  end

  def results
    calls.map do |f|
      f.call
    rescue NoMethodError => e
      [e.name, e.args, e.receiver.class]
    end
  end
end

c = Card.new
c.answers
p c.results
c.name; c.peer; c.opts; c.list
p c.results

def label(s = nil) = [s.to_a, s.to_h, s & 1, s | 1, s ^ 1]
p label
p((label("x") rescue :raised))

names = {a: "s"}
p names[:b].to_a, names[:b].to_h, names[:b] & 1, names[:b] | 1
