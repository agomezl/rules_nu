load("//nu/private:providers.bzl", "NuInfo")

def _nu_library_impl(ctx):
    return [
        DefaultInfo(files = depset(ctx.files.srcs)),
        NuInfo(scripts = ctx.files.srcs, deps = ctx.attr.deps),
    ]

nu_library = rule(
    implementation = _nu_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".nu"]),
        "deps": attr.label_list(providers = [NuInfo]),
    },
    provides = [NuInfo],
)
