# spinel: int64
# A boxed Array times a Float count past the length an Array can have is
# CRuby's ArgumentError; the Integer count's arm would fill memory first.

row = [[1, 2], 7]
cnt = [9.0e18, :k]
begin
  p row[0] * cnt[0]
rescue ArgumentError => e
  puts "#{e.class}: #{e.message}"
end
