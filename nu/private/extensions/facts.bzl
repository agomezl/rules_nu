NUSHELL_RELEASES_URL = "https://github.com/nushell/nushell/releases"

def _download_sha256sums(mctx, *, path, version = None):
    if version:
        url = "{}/download/{}/SHA256SUMS".format(NUSHELL_RELEASES_URL, version)
    else:  # Get the latest
        url = "{}/latest/download/SHA256SUMS".format(NUSHELL_RELEASES_URL)

    result = mctx.download(path = path, url = url)
    if not result.success:
        fail("Failed to download SHA256SUMS: {}".format(result.error))

    return path

def _fetch_version_facts(mctx, *, version):
    sha256sums = _download_sha256sums(
        mctx,
        path = "{}/SHA256SUMS".format(version),
        version = version,
    )

    # Sha256sum line format: <sha256>  <artifact>
    artifacts = {
        artifact: sha256
        for line in mctx.read(sha256sums).splitlines()
        for artifact, sha256 in [line.split("  ")]
        if artifact.endswith(".tar.gz") or artifact.endswith(".zip")
    }

    available_versions = {}
    for artifact, sha256 in artifacts.items():
        id = artifact.removesuffix(".tar.gz").removesuffix(".zip")
        available_versions[id]["sha256"] = sha256
        available_versions[id]["url"] = "{}/download/{}/{}".format(
            NUSHELL_RELEASES_URL,
            version,
            artifact,
        )

    return available_versions

def _resolve_latest(mctx):
    latest_sha256sums = _download_sha256sums(mctx, path = "latest/SHA256SUMS")

    # Sha256sum line format: <sha256>  nu-<version>-<platform>
    latest_version = (
        mctx.read(latest_sha256sums)
            .splitlines()[0]  # Take only the first line
            .split("-", 3)[1]  # Split on '-' to get the version
    )
    return latest_version

def update_facts(mctx, *, version, facts):
    new_facts = {}
    if not version and not "latest" in facts:
        version = _resolve_latest(mctx)
        new_facts["latest"] = version

    if version in facts:
        return new_facts

    new_facts[version] = _fetch_version_facts(mctx, version = version)
