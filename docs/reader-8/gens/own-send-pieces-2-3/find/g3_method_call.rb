class Own
  def send(msg, *rest) = method(msg).call(*rest)
  def ping = "Own#ping"
end
p Own.new.send(:ping)
