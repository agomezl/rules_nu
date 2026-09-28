# Calls the `tools` executable, whose runfiles path is the second argument.
def main [_launcher_path: string, tool_key: string] {
    let rf = (runfiles create)
    let out = (^(runfiles rlocation $rf $tool_key) | complete)
    if $out.exit_code != 0 or $out.stdout != "Some Data!\n" {
        error make {msg: $'unexpected tool result: ($out)'}
    }
}
