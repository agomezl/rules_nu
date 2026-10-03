def _fetch_version_facts(mctx, *, version):
    pass

def _resolve_latest(mctx):
    pass

def update_facts(mctx, *, version, facts):
    new_facts = {}
    if not version and not "latest" in facts:
        version = _resolve_latest(mctx)
        new_facts["latest"] = version

    if version in facts:
        return new_facts

    new_facts[version] = _fetch_version_facts(mctx, version = version)
