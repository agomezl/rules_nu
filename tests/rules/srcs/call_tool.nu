let rf = (runfiles create)
let out = (^(runfiles rlocation $rf "_main/nu_binary/tool") | complete)
if $out.exit_code != 0 or $out.stdout != "Some Data!\n" {
    error make {msg: $'unexpected tool result: ($out)'}
}
