load("@hermetic_launcher//launcher:lib.bzl", "launcher")

# Stolen from:
# https://github.com/hermeticbuild/hermetic-launcher/blob/main/launcher/private/rules/lib.bzl#L21C1-L24C35
def _to_rlocation_path(f):
    if f.short_path.startswith("../"):
        return f.short_path[3:]
    return "_main/" + f.short_path

def _wrapped_binary_test_impl(ctx):
    binary = ctx.executable.binary
    test_binary = ctx.actions.declare_file(ctx.label.name)
    entrypoint = launcher.entrypoint(binary)
    inputs = []
    if ctx.file.input:
        entrypoint = (
            entrypoint
                .runfiles(ctx.file.input)
                .embedded_args(_to_rlocation_path(ctx.file.input))
        )
        inputs.append(ctx.file.input)

    entrypoint.compile(
        ctx,
        output_file = test_binary,
        cfg = "exec",
    )

    runfiles = ctx.runfiles(
        files = inputs,
    )
    runfiles = runfiles.merge(ctx.attr.binary[DefaultInfo].default_runfiles)

    return [
        DefaultInfo(
            executable = test_binary,
            runfiles = runfiles,
        ),
    ]

wrapped_binary_test = rule(
    implementation = _wrapped_binary_test_impl,
    test = True,
    attrs = {
        "binary": attr.label(executable = True, cfg = "exec"),
        "input": attr.label(
            allow_single_file = True,
            doc = """
            A file to pass as input to the binary as both a runfiles-resolved
            (via the hermetic launcher) and a non-runfiles-resolved path
            """,
        ),
    },
    toolchains = [
        launcher.finalizer_toolchain_type,
        launcher.template_exec_toolchain_type,
    ],
)
