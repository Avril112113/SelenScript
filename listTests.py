from glob import iglob
from sys import argv

str = "{"
for path in iglob(argv[1], recursive=True):
	path = path.replace("\\", "\\\\")
	str += f"'{path}',"
str += "}"
print(str)
