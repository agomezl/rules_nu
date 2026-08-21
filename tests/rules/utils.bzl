load("@hermetic_launcher//launcher:lib.bzl", "launcher")

def _wrapped_binary_test_impl(ctx):
    binary = ctx.executable.binary
    test_binary = ctx.actions.declare_file(ctx.label.name)
    launcher.entrypoint(binary).compile(
        ctx,
        output_file = test_binary,
        cfg = "exec",
    )

    return [
        DefaultInfo(
            executable = test_binary,
            runfiles = ctx.attr.binary[DefaultInfo].default_runfiles,
        ),
    ]

wrapped_binary_test = rule(
    implementation = _wrapped_binary_test_impl,
    test = True,
    attrs = {
        "binary": attr.label(executable = True, cfg = "exec"),
    },
    toolchains = [
        launcher.finalizer_toolchain_type,
        launcher.template_exec_toolchain_type,
    ],
)
