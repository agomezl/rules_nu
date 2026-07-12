def _nu_info_impl(scripts, deps):
    if not all([NuInfo in dep for dep in deps]):
        fail("All dependencies must be NuInfo providers")

    return {
        "scripts": depset(
            direct = scripts,
            transitive = [dep[NuInfo].scripts for dep in deps],
            order = "postorder",
        ),
    }

NuInfo, _new_nu_info = provider(
    init = _nu_info_impl,
    fields = {
        "scripts": """
        The set of nushell scripts to include/use in dependency order
        """,
    },
)
