let rf = (runfiles create)
if $rf == null {
    error make { msg: "could not locate runfiles" }
}
let data_path = (runfiles rlocation $rf "_main/data/data1.txt")

let data = open $data_path

if $data == "Some Data!\n" {
    exit 0
} else {
    exit 1
}
