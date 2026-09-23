
def main [hermetic_launcher_path : string, runfiles_path : string] {
    let rf = (runfiles create)
    let data_path = (runfiles rlocation $rf $runfiles_path)

    print $"hermetic launcher path: ($hermetic_launcher_path)"
    print $"data path: ($data_path)"
    if $data_path == $hermetic_launcher_path {
        exit 0
    } else {
        error make { msg: "data path does not match hermetic launcher path" }
    }
}
