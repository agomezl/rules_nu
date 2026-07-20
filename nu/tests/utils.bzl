load("@hermetic_launcher//launcher:lib.bzl", "launcher")

def _wrapped_binary_test_impl(ctx):
    binary = ctx.executable.binary
    test_binary = ctx.actions.declare_file(ctx.label.name)
    embedded, transformed = launcher.args_from_entrypoint(binary)
    launcher.compile_stub(
        ctx = ctx,
        embedded_args = embedded,
        transformed_args = transformed,
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
