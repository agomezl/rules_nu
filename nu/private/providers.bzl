def _nu_info_impl(ctx, scripts, deps):
    if not all([NuInfo in dep for dep in deps]):
        fail("All dependencies must be NuInfo providers")

    runfiles = ctx.runfiles(
        files = scripts,
        symlinks = {
            "_NU_LIBS/{}/{}".format(
                f.owner.package or ".",
                f.owner.name,
            ): f
            for f in scripts
        },
    )
    runfiles = runfiles.merge_all([dep[NuInfo].runfiles for dep in deps])

    return {
        "scripts": depset(
            direct = scripts,
            transitive = [dep[NuInfo].scripts for dep in deps],
            order = "postorder",
        ),
        "runfiles": runfiles,
    }

NuInfo, _new_nu_info = provider(
    init = _nu_info_impl,
    fields = {
        "scripts": """
        The set of nushell scripts to include/use in dependency order
        """,
        "runfiles": """
        The runfiles for the nushell binary
        """,
    },
)
