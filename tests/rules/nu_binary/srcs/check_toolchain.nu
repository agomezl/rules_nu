let nu_exe: string = ($nu.current-exe | str trim)
let heuristic_paths: list<string> = ["_main", "external", '\+nu\+']
if not ($heuristic_paths | any {|path| $nu_exe =~ $path}) {
    error make {msg: $'nu binary is not from a toolchain: ($nu_exe)'}
}
