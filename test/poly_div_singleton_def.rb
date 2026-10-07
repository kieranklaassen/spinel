# A `/` given to nil, true or false themselves (`def nil./(o)`) is a
# method the boxed division does not reach: it converts the value, which
# is what these methods answer. Such a program is left as it was.
def nil./(o) = 0
def true./(o) = 1
def false./(o) = 0

row = [nil, 2, true, false, 1]
p row[0] / row[1]
p row[2] / row[4]
p row[3] / row[1]

a = row[0]
b = row[1]
p a / b

def calc(a, b) = a / b
p calc(row[0], 2)
p calc(row[2], 1)
p calc(row[3], 2)
p calc(7, 2)
