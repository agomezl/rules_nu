def _format_library_path(file):
    return "_NU_LIBS/{}/{}".format(
        file.owner.package or ".",
        file.owner.name,
    )

def _nu_info_impl(ctx, scripts, deps):
    if not all([NuInfo in dep for dep in deps]):
        fail("All dependencies must be NuInfo providers")

    symlinks = []
    for script in scripts:
        symlink = ctx.actions.declare_file(_format_library_path(script))
        symlinks.append(symlink)
        ctx.actions.symlink(output = symlink, target_file = script)

    runfiles = ctx.runfiles(
        files = scripts,
        symlinks = {_format_library_path(f): f for f in scripts},
    )
    runfiles = runfiles.merge_all([dep[NuInfo].runfiles for dep in deps])

    return {
        "scripts": depset(
            direct = scripts + symlinks,
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
