load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load(
    "@rules_nu//nu/private/extensions:defs.bzl",
    "NUSHELL_CONSTRAINTS_MAP",
    "NUSHELL_PLATFORM_ID",
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

def resolve_release(mctx, facts, version, os, arch):
    """Returns (version, platform, sha256) for a release.

    An empty *version* means the latest release. Values are looked up in
    *facts* (persisted in MODULE.bazel.lock) and otherwise read from the
    SHA256SUMS file published with the release.
    """
    platform = _get_platform_identifier(os, arch)
    version = version or facts.get("latest")
    if version and version + "/" + platform in facts:
        return version, platform, facts[version + "/" + platform]

    url = "https://github.com/nushell/nushell/releases/{}/SHA256SUMS".format(
        "download/" + version if version else "latest/download",
    )
    mctx.download(url, "SHA256SUMS")
    suffix = "-{}.{}".format(platform, _archive_ext(platform))
    for line in mctx.read("SHA256SUMS").splitlines():
        sha256, _, asset = line.partition("  ")
        if asset.startswith("nu-") and asset.endswith(suffix):
            return asset[len("nu-"):-len(suffix)], platform, sha256
    fail("No release asset for {} in Nushell {}".format(platform, version or "latest"))

def _archive_ext(platform):
    return "zip" if "windows" in platform else "tar.gz"

def create_version(version, platform, sha256):
    """Creates an http_archive for *version* on the given *platform*.

    Returns (repo_name, constraints) so the caller can register it in the hub.
    """
    constraints = _get_platform_constraints(platform)

    repo_name = "nu_{}_{}".format(
        version.replace(".", "_"),
        platform.replace("-", "_"),
    )

    http_archive(
        name = repo_name,
        url = "https://github.com/nushell/nushell/releases/download/{v}/nu-{v}-{p}.{e}".format(
            v = version,
            p = platform,
            e = _archive_ext(platform),
        ),
        sha256 = sha256,
        # Windows archives are flat; the others have a top-level directory.
        strip_prefix = "" if "windows" in platform else "nu-{}-{}".format(version, platform),
        build_file_content = PER_PLATFORM_BUILD_TEMPLATE.format(
            nu_path = "nu.exe" if "windows" in platform else "nu",
        ),
    )

    return repo_name, constraints
