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

def _archive_url(version, platform):
    return "https://github.com/nushell/nushell/releases/download/{v}/nu-{v}-{p}.{e}".format(
        v = version,
        p = platform,
        e = "zip" if "windows" in platform else "tar.gz",
    )

def resolve_release(mctx, facts, version, os, arch):
    """Returns (version, platform, sha256) for a release.

    An empty *version* means the latest release. Values are looked up in
    *facts* (persisted in MODULE.bazel.lock); anything missing is downloaded
    once to compute its hash.
    """
    platform = _get_platform_identifier(os, arch)
    if not version:
        version = facts.get("latest")
    if not version:
        mctx.download("https://api.github.com/repos/nushell/nushell/releases/latest", "latest.json")
        version = json.decode(mctx.read("latest.json"))["tag_name"]
    sha256 = facts.get(version + "/" + platform)
    if not sha256:
        sha256 = mctx.download(_archive_url(version, platform), "nu_archive").sha256
        mctx.delete("nu_archive")
    return version, platform, sha256

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
        url = _archive_url(version, platform),
        sha256 = sha256,
        # Windows archives are flat; the others have a top-level directory.
        strip_prefix = "" if "windows" in platform else "nu-{}-{}".format(version, platform),
        build_file_content = PER_PLATFORM_BUILD_TEMPLATE.format(
            nu_path = "nu.exe" if "windows" in platform else "nu",
        ),
    )

    return repo_name, constraints
