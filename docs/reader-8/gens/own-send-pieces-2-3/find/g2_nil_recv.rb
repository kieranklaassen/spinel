class Own
  def send(msg, flags = 0) = "own:#{msg}:#{flags}"
end
2.times do |i|
  x = i == 0 ? Own.new : nil
  p x.send(:==, nil)
end
