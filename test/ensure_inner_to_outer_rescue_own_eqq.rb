# A rescue clause asks the class's own `===`. Where a program holds a def
# or a Symbol of that name, an exception that leaves an inner ensure is
# handed on as it was: the clauses of the begin around it are not offered it.

class Never < StandardError
  def self.===(e) = false
end
module Tag
  def self.===(e) = false
end
class Tagged < StandardError
  include Tag
end
class Quiet < StandardError
  class << self
    def ===(e) = false
  end
end

$log = []
def run(tag)
  yield
  $log << "#{tag}: returned"
rescue Exception => e
  $log << "#{tag}: out #{e.class}"
end

run("class") do
  begin
    begin
      raise Never, "n"
    ensure
      $log << "inner"
    end
  rescue Never
    $log << "rescued"
  ensure
    $log << "outer"
  end
end
run("module") do
  begin
    begin
      raise Tagged, "t"
    ensure
      $log << "inner"
    end
  rescue Tag
    $log << "rescued"
  ensure
    $log << "outer"
  end
end
run("singleton class") do
  begin
    begin
      raise Quiet, "q"
    ensure
      $log << "inner"
    end
  rescue Quiet
    $log << "rescued"
  ensure
    $log << "outer"
  end
end
puts $log
