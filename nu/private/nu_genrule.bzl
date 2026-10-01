load("@hermetic_launcher//launcher:lib.bzl", "launcher")
load("//nu/private:nu_binary.bzl", "nu_binary")
load("//nu/private:nu_library.bzl", "nu_library")

# A minimal stand-in for `@bazel_skylib//rules:write_file.bzl`'s `write_file`.
_write_nu_script = rule(
    implementation = lambda ctx: ctx.actions.write(
        output = ctx.outputs.out,
        content = ctx.attr.content,
    ),
    attrs = {
        "content": attr.string(mandatory = True),
        "out": attr.output(mandatory = True),
    },
)

def _label_aliases(label, rule_label):
    """Spellings of `label` that `target location` accepts, canonical one first."""
    aliases = [str(label)]
    if label.repo_name == rule_label.repo_name:
        aliases.append("//{}:{}".format(label.package, label.name))
        if label.name == label.package.split("/")[-1]:
            aliases.append("//{}".format(label.package))
        if label.package == rule_label.package:
            aliases.append(":{}".format(label.name))
    return aliases

def _target_files(target):
    """Runfiles-relative paths that `target` expands to for `target location(s)`."""
    executable = target[DefaultInfo].files_to_run.executable
    files = [executable] if executable else target[DefaultInfo].files.to_list()
    return [launcher.to_rlocation_path(f) for f in files]

def _nu_genrule_run_impl(ctx):
    targets = {
        alias: files
        for target in ctx.attr.inputs + ctx.attr.tools + ctx.attr.data
        for files in [_target_files(target)]
        for alias in _label_aliases(target.label, ctx.label)
    }

    targets_file = ctx.actions.declare_file("{}.targets.json".format(ctx.label.name))
    ctx.actions.write(targets_file, json.encode(targets))

    output_args = ctx.actions.args()
    output_args.add_all(ctx.outputs.outputs)
    output_args.use_param_file("%s", use_always = True)

    targets_args = ctx.actions.args()
    targets_args.add(targets_file)

    ctx.actions.run(
        executable = ctx.executable.binary,
        arguments = [output_args, targets_args],
        inputs = depset(
            [targets_file] + ctx.files.inputs,
            transitive = [d[DefaultInfo].files for d in ctx.attr.data],
        ),
        tools = [tool[DefaultInfo].files_to_run for tool in ctx.attr.tools],
        outputs = ctx.outputs.outputs,
        mnemonic = "NuGenrule",
        progress_message = "Running nu_genrule %{label}",
    )

_nu_genrule_run = rule(
    implementation = _nu_genrule_run_impl,
    doc = "Runs the pre-compiled nu_binary executable",
    attrs = {
        "binary": attr.label(executable = True, cfg = "exec", mandatory = True),
        "inputs": attr.label_list(allow_files = True),
        "tools": attr.label_list(cfg = "exec"),
        "data": attr.label_list(allow_files = True),
        "outputs": attr.output_list(mandatory = True, allow_empty = False),
    },
)

def _nu_genrule_script(cmd):
    return """use nu/private/target.nu

def main [outputs_file: string, targets_file: string] {{
    let outputs = (open $outputs_file | lines)
    $env._NU_GENRULE = {{
        targets: (open $targets_file)
        runfiles: (runfiles create)
    }}
    let bazel = {{
        outputs: $outputs
    }}
{cmd}
}}
""".format(cmd = cmd)

def _nu_genrule_impl(name, visibility, cmd, outputs, inputs, tools, deps, data, **kwargs):
    script_name = "{}_main".format(name)
    binary_name = "{}_bin".format(name)
    data_deps_library = "{}_data_deps".format(name)

    _write_nu_script(
        name = script_name,
        out = "{}.nu".format(name),
        content = _nu_genrule_script(cmd),
    )

    # We require this intermediate `nu_library` to allow `data` and `deps` to be
    # configurable. The trivial solution is to use `data = inputs + data` in
    # `nu_binary`, but this analysis-time evaluation is not allowed on
    # configurable attributes.
    nu_library(
        name = data_deps_library,
        data = data,
        deps = deps,
    )

    nu_binary(
        name = binary_name,
        main = script_name,
        deps = [data_deps_library, Label("//nu/private:target")],
        data = inputs,
        tools = tools,
        cfg = "exec",
    )

    _nu_genrule_run(
        name = name,
        visibility = visibility,
        binary = binary_name,
        inputs = inputs,
        tools = tools,
        data = data,
        outputs = outputs,
        **kwargs
    )

nu_genrule = macro(
    doc = "Generates `outputs` by running a nushell command.",
    implementation = _nu_genrule_impl,
    inherit_attrs = "common",
    attrs = {
        "cmd": attr.string(
            doc = """
            The nushell command to run. The file path in a target can be
            expanded using `target location "<label>"` with labels from
            `inputs`, `tools` or `data`. For targets with multiple files, use
            `target locations "<label>"`.
            """,
            mandatory = True,
            configurable = False,
        ),
        "outputs": attr.output_list(
            doc = "The output files generated by `cmd`.",
            mandatory = True,
            allow_empty = False,
        ),
        "inputs": attr.label_list(
            doc = "Input files, addressable by label via `target location(s)` (and runfiles).",
        ),
        "tools": attr.label_list(
            doc = """
            Executable targets that `cmd` can call; their resolved paths are
            available via `target location`.
            """,
        ),
        "deps": attr.label_list(
            doc = "Nushell modules dependencies available to `cmd` via `use`.",
        ),
        "data": attr.label_list(
            doc = "Additional files available to `cmd` via `target location(s)` and `runfiles`.",
        ),
    },
)
