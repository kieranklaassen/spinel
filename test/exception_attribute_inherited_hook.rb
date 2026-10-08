# A parent's `inherited` hook gives the subclass its initialize, which
# CRuby runs for every object of it: the attribute it stores a zero in
# reads that zero, raised by name or made by `new`.
class Base < StandardError
  def self.inherited(k)
    k.class_eval do
      def initialize(m = nil)
        super
        @count = 0
      end
    end
  end
end
class Counted < Base
  attr_accessor :count
end
p Counted.new("m").count
begin
  raise Counted, "r"
rescue Counted => e
  p e.count, e.message
end
kept = []
begin
  raise Counted, "s"
rescue StandardError => e
  kept << e
end
kept.each { |v| p v.count if v.respond_to?(:count) }
