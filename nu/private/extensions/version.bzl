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
        e = _ext(platform),
    )

def _ext(platform):
    return "zip" if "windows" in platform else "tar.gz"

def resolve_release(mctx, known, facts, version, os, arch):
    """Returns (version, platform, sha256) for a release.

    An empty *version* means the latest release. Hashes come from *known*
    (the facts persisted in MODULE.bazel.lock) or, when missing, from the
    SHA256SUMS file published with the release. The hashes of every platform
    of the version are recorded in *facts*, so using another platform later
    does not change the lockfile.
    """
    platform = _get_platform_identifier(os, arch)
    version = version or known.get("latest")
    sums = {}
    if not version or version + "/" + platform not in known:
        mctx.download(
            "https://github.com/nushell/nushell/releases/{}/SHA256SUMS".format(
                "download/" + version if version else "latest/download",
            ),
            "SHA256SUMS",
        )
        assets = {}  # asset name -> sha256
        for line in mctx.read("SHA256SUMS").splitlines():
            sha256, _, asset = line.partition("  ")
            assets[asset] = sha256
        if not version:
            suffix = "-{}.{}".format(platform, _ext(platform))
            version = [a for a in assets if a.startswith("nu-") and a.endswith(suffix)][0][len("nu-"):-len(suffix)]
        for p in NUSHELL_CONSTRAINTS_MAP:
            sha256 = assets.get("nu-{}-{}.{}".format(version, p, _ext(p)))
            if sha256:
                sums[p] = sha256

    for p in NUSHELL_CONSTRAINTS_MAP:
        sha256 = sums.get(p) or known.get(version + "/" + p)
        if sha256:
            facts[version + "/" + p] = sha256
    if platform not in sums and version + "/" + platform not in known:
        fail("No Nushell {} release asset for {}".format(version, platform))
    return version, platform, facts[version + "/" + platform]

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
