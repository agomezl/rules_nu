load("@hermetic_launcher//launcher:lib.bzl", "launcher")
load("//nu/private:providers.bzl", "NuInfo")
load("//nu/toolchains:defs.bzl", "NUSHELL_TOOLCHAIN_TYPE")

def _nu_binary_impl(ctx):
    nu = ctx.toolchains[NUSHELL_TOOLCHAIN_TYPE].nu

    all_modules = [dep[NuInfo].scripts for dep in ctx.attr.deps]
    all_scripts = depset([ctx.file.main], transitive = all_modules)

    exe = ctx.actions.declare_file(ctx.label.name)

    embedded, transformed = launcher.args_from_entrypoint(nu)
    embedded, transformed = launcher.append_embedded_arg(
        arg = "-n",
        embedded_args = embedded,
        transformed_args = transformed,
    )
    embedded, transformed = launcher.append_runfile(
        file = ctx.file.main,
        embedded_args = embedded,
        transformed_args = transformed,
    )
    launcher.compile_stub(
        ctx = ctx,
        embedded_args = embedded,
        transformed_args = transformed,
        output_file = exe,
        cfg = "target",
    )

    runfiles = ctx.runfiles(files = [nu], transitive_files = all_scripts)

    return [
        DefaultInfo(
            executable = exe,
            runfiles = runfiles,
        ),
    ]

nu_binary = rule(
    implementation = _nu_binary_impl,
    attrs = {
        "main": attr.label(
            doc = "The main nushell script to execute",
            allow_single_file = [".nu"],
            mandatory = True,
        ),
        "deps": attr.label_list(
            doc = "Nushell module dependencies",
            providers = [NuInfo],
        ),
    },
    executable = True,
    toolchains = [
        NUSHELL_TOOLCHAIN_TYPE,
        launcher.finalizer_toolchain_type,
        launcher.template_toolchain_type,
    ],
    provides = [NuInfo],
)
