# Test tool: prints a data file found through its own runfiles.
let rf = (runfiles create)
open (runfiles rlocation $rf "_main/data/data1.txt") | print --no-newline
