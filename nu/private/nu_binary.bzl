load("@hermetic_launcher//launcher:lib.bzl", "launcher")
load("//nu/private:providers.bzl", "NuInfo")
load("//nu/toolchains:defs.bzl", "NUSHELL_TOOLCHAIN_TYPE")

def _nu_binary_impl(ctx):
    nu = ctx.toolchains[NUSHELL_TOOLCHAIN_TYPE].nu
    exe = ctx.actions.declare_file(ctx.label.name)
    inputs = [nu, ctx.file.main, ctx.file._config, ctx.file._env_config]
    runfiles = ctx.runfiles(files = inputs)
    runfiles = runfiles.merge_all([dep[NuInfo].runfiles for dep in ctx.attr.deps])

    embedded, transformed = launcher.args_from_entrypoint(nu)
    embedded, transformed = launcher.append_embedded_arg(
        arg = "--env-config",
        embedded_args = embedded,
        transformed_args = transformed,
    )
    embedded, transformed = launcher.append_runfile(
        file = ctx.file._env_config,
        embedded_args = embedded,
        transformed_args = transformed,
    )
    embedded, transformed = launcher.append_embedded_arg(
        arg = "--config",
        embedded_args = embedded,
        transformed_args = transformed,
    )
    embedded, transformed = launcher.append_runfile(
        file = ctx.file._config,
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
        "_env_config": attr.label(
            doc = "Nushell env.nu file",
            allow_single_file = [".nu"],
            mandatory = False,
            default = "//nu/private:env.nu",
        ),
        "_config": attr.label(
            doc = "Nushell config.nu file",
            allow_single_file = [".nu"],
            mandatory = False,
            default = "//nu/private:config.nu",
        ),
    },
    executable = True,
    toolchains = [
        NUSHELL_TOOLCHAIN_TYPE,
        launcher.finalizer_toolchain_type,
        launcher.template_toolchain_type,
    ],
)
