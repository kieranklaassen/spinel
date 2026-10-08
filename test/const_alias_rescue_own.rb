# A class that answers === itself is asked at the rescue: a constant holding
# it is not read as the class's name there.
class Quiet < StandardError
  def self.===(e) = false
end
Q = Quiet
begin
  begin
    raise Quiet, "q"
  rescue Q
    puts "wrong arm"
  end
rescue StandardError => e
  puts "outer #{e.class}"
end
