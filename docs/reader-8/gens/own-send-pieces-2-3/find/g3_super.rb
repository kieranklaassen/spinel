class Own
  def send(msg, *rest) = super(msg, *rest)
  def ping = "Own#ping"
end
p Own.new.send(:ping)
