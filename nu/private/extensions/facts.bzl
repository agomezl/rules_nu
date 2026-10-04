NUSHELL_RELEASES_URL = "https://github.com/nushell/nushell/releases"
LATEST_SHA256SUM_PATH = "latest/SHA256SUMS"

# buildifier: disable=uninitialized
def create_facts(mctx):
    facts = mctx.facts
    current_facts = {}

    def _get(self, key):
        value = self._facts().get(key)
        current_value = self._current_facts().get(key)

        # We store every unseen value in current_facts to ensure
        # that only the facts that are relevant to this evaluation
        # are returned.
        if value and not current_value:
            self._current_facts()[key] = value

        return current_value or value

    def _insert(self, key, value):
        self._current_facts()[key] = value

    self = struct(
        _facts = lambda: facts,
        _current_facts = lambda: current_facts,
        get = lambda key: _get(self, key),
        insert = lambda key, value: _insert(self, key, value),
        contains = lambda key: bool(_get(self, key)),
        all = lambda: self._current_facts(),
    )

    return self

def _download_sha256sums(mctx, *, path, version = None):
    if version:
        url = "{}/download/{}/SHA256SUMS".format(NUSHELL_RELEASES_URL, version)
    else:  # Get the latest
        url = "{}/latest/download/SHA256SUMS".format(NUSHELL_RELEASES_URL)

    result = mctx.download(url = url, output = path)
    if not result.success:
        fail("Failed to download SHA256SUMS: {}".format(result.error))

    return path

def _fetch_version_facts(mctx, *, version, path = None):
    if not path:
        path = _download_sha256sums(
            mctx,
            path = "{}/SHA256SUMS".format(version),
            version = version,
        )

    # Sha256sum line format: <sha256>  nu-<version>-<artifact>.<ext>
    artifacts = {
        artifact: sha256
        for line in mctx.read(path).splitlines()
        for sha256, artifact in [tuple(line.split("  "))]
        if artifact.endswith(".tar.gz") or artifact.endswith(".zip")
    }

    available_versions = {}
    for artifact, sha256 in artifacts.items():
        id = (
            artifact
                .split(version)[1]
                .removeprefix("-")
                .removesuffix(".tar.gz")
                .removesuffix(".zip")
        )
        available_versions[id] = {}
        available_versions[id]["sha256"] = sha256
        available_versions[id]["url"] = "{}/download/{}/{}".format(
            NUSHELL_RELEASES_URL,
            version,
            artifact,
        )

    return available_versions

def _resolve_latest(mctx):
    latest_sha256sums = _download_sha256sums(mctx, path = LATEST_SHA256SUM_PATH)

    # Sha256sum line format: <sha256>  nu-<version>-<platform>
    latest_version = (
        mctx.read(latest_sha256sums)
            .splitlines()[0]  # Take only the first line
            .split("-", 3)[1]  # Split on '-' to get the version
    )
    return latest_version

def _update_latest_version(mctx, *, facts):
    path = None
    version = facts.get("latest")
    if not version:
        version = _resolve_latest(mctx)
        facts.insert("latest", version)
        path = LATEST_SHA256SUM_PATH

    _update_version(
        mctx,
        version = version,
        facts = facts,
        path = path,
    )

def _update_version(mctx, *, version, facts, path = None):
    if not facts.contains(version):
        facts.insert(
            version,
            _fetch_version_facts(mctx, version = version, path = path),
        )

def update_facts(mctx, *, version, facts):
    if version:
        _update_version(mctx, version = version, facts = facts)
    else:
        _update_latest_version(mctx, facts = facts)
