def main [tag = "HEAD", --dir = ".", --quiet] {
    cd $env.BUILD_WORKSPACE_DIRECTORY
    let dist = $dir | path expand -s | path join "dist"
    rm -fr $dist
    mkdir $dist
    git archive --format=tar.gz --output=$'($dist)/rules_nu-($tag).tar.gz' --no-prefix HEAD

    if not $quiet {
        release_notes ($tag | parse "v{version}" | get -o 0.version | default "...")
    }
}

def release_notes [version:string] {
    $"## Rules nu

This release contains Nushell rules for Bazel.

### Usage

```starlark
bazel_dep\(name = \"rules_nu\", version = \"($version)\"\)
```
" | print
}
