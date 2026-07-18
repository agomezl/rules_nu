load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load(
    "@rules_nu//nu/private/extensions:defs.bzl",
    "NUSHELL_CONSTRAINTS_MAP",
    "NUSHELL_PLATFORM_ID",
    "NUSHELL_RELEASES",
)
load("@rules_nu//nu/private/extensions:templates.bzl", "PER_PLATFORM_BUILD_TEMPLATE")

def _get_platform_identifier(os, arch):
    if os not in NUSHELL_PLATFORM_ID or arch not in NUSHELL_PLATFORM_ID[os]:
        fail("Unsupported platform: {} on {}".format(arch, os))
    return NUSHELL_PLATFORM_ID[os][arch]

def _get_platform_constraints(platform):
    if platform not in NUSHELL_CONSTRAINTS_MAP:
        fail("Unknown platform: {}".format(platform))
    return NUSHELL_CONSTRAINTS_MAP[platform]

def _get_release_hash(version, platform):
    if version not in NUSHELL_RELEASES:
        fail("Version {} not found in NUSHELL_RELEASES. Available versions: {}".format(
            version,
            ", ".join(sorted(NUSHELL_RELEASES.keys())),
        ))
    version_data = NUSHELL_RELEASES[version]
    if platform not in version_data:
        fail("Platform {} not available for version {}. Available platforms: {}".format(
            platform,
            version,
            ", ".join(sorted(version_data.keys())),
        ))
    return version_data[platform]

def create_version(version, os, arch):
    """Creates an http_archive for *version* on the given *os*/*arch*.

    Returns (repo_name, constraints) so the caller can register it in the hub.
    """
    platform = _get_platform_identifier(os, arch)
    sha256 = _get_release_hash(version, platform)
    constraints = _get_platform_constraints(platform)

    repo_name = "nu_{}_{}".format(
        version.replace(".", "_"),
        platform.replace("-", "_"),
    )

    http_archive(
        name = repo_name,
        url = "https://github.com/nushell/nushell/releases/download/{v}/nu-{v}-{p}.tar.gz".format(
            v = version,
            p = platform,
        ),
        sha256 = sha256,
        build_file_content = PER_PLATFORM_BUILD_TEMPLATE.format(
            nu_path = "nu-{}-{}/nu".format(version, platform),
        ),
    )

    return repo_name, constraints
