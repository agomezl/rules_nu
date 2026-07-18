load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load(
    "@rules_nu//nu/private/extensions:defs.bzl",
    "NUSHELL_CONSTRAINTS_MAP",
    "NUSHELL_PLATFORM_ID",
    "NUSHELL_RELEASES",
)
load("@rules_nu//nu/private/extensions:templates.bzl", "BUILD_FILE_TEMPLATE")

def _get_platform_identifier(os, arch):
    if os not in NUSHELL_PLATFORM_ID or arch not in NUSHELL_PLATFORM_ID[os]:
        fail("Unsupported platform: {} on {}".format(os, arch))

    return NUSHELL_PLATFORM_ID[os][arch]

def _get_platform_constraints(platform):
    if platform not in NUSHELL_CONSTRAINTS_MAP:
        fail("Unknown platform: {}".format(platform))

    return NUSHELL_CONSTRAINTS_MAP[platform]

def _get_release_hash(version, platform):
    """Get the SHA256 hash for a nushell release."""
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

def _construct_release_url(version, platform):
    """Construct the GitHub release download URL for a given version and platform."""
    return "https://github.com/nushell/nushell/releases/download/{version}/nu-{version}-{platform}.tar.gz".format(
        version = version,
        platform = platform,
    )

def create_version(name, version, os, arch):
    platform = _get_platform_identifier(os, arch)
    sha256 = _get_release_hash(version, platform)
    url = _construct_release_url(version, platform)
    repo_name = name
    constraints = _get_platform_constraints(platform)

    # Construct the path to the nu binary within the archive
    nu_binary_path = "nu-{version}-{platform}/nu".format(
        version = version,
        platform = platform,
    )

    # Format constraints list for the BUILD file template
    constraints_str = "[" + ", ".join(['"{}"'.format(c) for c in constraints]) + "]"

    http_archive(
        name = repo_name,
        url = url,
        sha256 = sha256,
        build_file_content = (
            BUILD_FILE_TEMPLATE.format(
                name = repo_name,
                nu_path = nu_binary_path,
                exec_compatible_with = constraints_str,
            )
        ),
    )
