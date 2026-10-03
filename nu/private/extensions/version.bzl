load(
    "//nu/private/extensions:defs.bzl",
    "NUSHELL_ARCH_CONSTRAINTS_MAP",
    "NUSHELL_OS_CONSTRAINTS_MAP",
    "NUSHELL_PLATFORM_ID",
)
load("//nu/private/extensions:templates.bzl", "PER_PLATFORM_BUILD_TEMPLATE")

def _canonical_os(os):
    os_name = os.lower()
    if any([os_name.startswith(x) for x in ("mac", "darwin")]):
        return "macos"
    if os_name.startswith("windows"):
        return "windows"
    return os_name

def _canonical_arch(arch):
    arch = arch.lower()
    if arch in ("amd64", "x86_64", "x64"):
        return "x86_64"
    if arch in ("aarch64", "arm64"):
        return "aarch64"
    return arch

def _get_platform_constraints(*, os, arch):
    if (os not in NUSHELL_OS_CONSTRAINTS_MAP or
        arch not in NUSHELL_ARCH_CONSTRAINTS_MAP):
        fail("Unsupported platform: {} on {}".format(arch, os))
    return [
        NUSHELL_OS_CONSTRAINTS_MAP[os],
        NUSHELL_ARCH_CONSTRAINTS_MAP[arch],
    ]

def _get_repo_name(*, platform, version):
    return "nu_{}_{}".format(
        version.replace(".", "_"),
        platform,
    )

def _get_build_file(*, os, version, id):
    nu_path = "nu.exe" if os == "windows" else "nu-{}-{}/nu".format(version, id)
    return PER_PLATFORM_BUILD_TEMPLATE.format(nu_path = nu_path)

def resolve_version(raw_version, raw_os, raw_arch, facts):
    os = _canonical_os(raw_os)
    arch = _canonical_arch(raw_arch)

    if os not in NUSHELL_PLATFORM_ID or arch not in NUSHELL_PLATFORM_ID[os]:
        fail("Unsupported platform: {} on {}".format(arch, os))

    id = NUSHELL_PLATFORM_ID[os][arch]
    version = raw_version or facts["latest"]
    constraints = _get_platform_constraints(os = os, arch = arch)
    repo_name = _get_repo_name(version = version, platform = id)
    build_file = _get_build_file(os = os, version = version, id = id)

    if version not in facts:
        # TODO: Add information on how to fix this
        fail("Version {} is not in MODULE.bazel.lock.".format(version))

    if id not in facts[version]:
        # TODO: Add information on how to fix this
        fail(
            "Platform {} is not in MODULE.bazel.lock for version {}".format(id, version),
        )

    url = facts[version][id]["url"]
    sha256 = facts[version][id]["sha256"]

    return struct(
        id = id,
        repo_name = repo_name,
        os = os,
        arch = arch,
        number = version,
        constraints = constraints,
        key = (version, os, arch),
        url = url,
        sha256 = sha256,
        build_file = build_file,
    )
