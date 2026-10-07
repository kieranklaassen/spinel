class Own
  def send(msg, *rest) = __send__(msg, *rest)
  def ping = "Own#ping"
end
p Own.new.send(:ping)
