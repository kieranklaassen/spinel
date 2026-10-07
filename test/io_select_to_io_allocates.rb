# IO.select with an error set answers the ready handles when an element's
# #to_io allocates, as CRuby does: the Array being filled lives through the
# collection that #to_io can cause. About one call in 3,000 answered
# [[], [], []] for a pipe with a byte to read.
class Wrap
  def initialize(io)
    @io = io
    @log = []
  end

  def to_io
    @log = [1, 2, 3, 4]
    @io
  end
end

r, w = IO.pipe
w.write "x"
w.flush
wrap = Wrap.new(r)
rd = [wrap]
er = [wrap]
bad = 0
i = 0
while i < 100000
  res = IO.select(rd, nil, er, 0)
  ok = !res.nil? && res.length == 3 && res[0].length == 1 && res[0][0].equal?(wrap) && res[1].empty? && res[2].empty?
  bad += 1 unless ok
  i += 1
end
p bad
