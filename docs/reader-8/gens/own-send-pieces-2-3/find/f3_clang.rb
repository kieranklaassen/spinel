class Own
  def send(msg, flags = 0) = "own:#{msg}:#{flags}"
end
xs = [Own.new, "five"]
xs.each { |x| p x.send(:==, "five") }
