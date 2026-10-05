# to_i and to_f on a nil held in an Array, a Hash or an object slot answer 0
# and 0.0: nil has both where the slot's class has neither.

class Peer; end

class Card
  def list = (@list ||= [1])
  def opts = (@opts ||= {a: 1})
  def peer = (@peer ||= Peer.new)

  def answers
    [@list.to_i, @list.to_f, @opts.to_i, @opts.to_f, @peer.to_i, @peer.to_f,
     @list.to_i + 1, @opts.to_f * 2, "#{@peer.to_i}"]
  end

  def calls = [-> { @list.to_i }, -> { @opts.to_f }, -> { @peer.to_i }]

  def results
    calls.map do |f|
      f.call
    rescue NoMethodError => e
      [e.name, e.args, e.receiver.class]
    end
  end
end

c = Card.new
p c.answers, c.results
c.list; c.opts; c.peer
p c.results

def count(rows = nil) = rows.to_i + 1
p count
p((count([1]) rescue :raised))
