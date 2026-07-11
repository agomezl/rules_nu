def _local_nu_repo_impl(rctx):
    local_nu_binary = rctx.which("nu")
    if not local_nu_binary:
        fail("nu binary not found in PATH")
    rctx.symlink(local_nu_binary, "nu")
    rctx.file(
        "BUILD",
        content = 'exports_files(["nu"])',
    )

local_nu_binary = repository_rule(
    implementation = _local_nu_repo_impl,
)
