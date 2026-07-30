def main [] {
    cd $env.BUILD_WORKSPACE_DIRECTORY
    print "== Build release archive =="
    bazel run //tools:release -- --quiet --dir "/tmp"
    cd tests/bcr
    print "== Build using archive as a dependency =="
    bazel build '@rules_nu//...'
}
