# Nushell releases database with platform-specific SHA256 hashes
# See: https://github.com/nushell/nushell/releases
NUSHELL_RELEASES = {
    "0.114.0": {
        "aarch64-apple-darwin": "c98f7deedd41023fe6dc4567abb368c9442bda62989b91e179e095cbb457ce58",
        "x86_64-apple-darwin": "0df0c980cf74a6ebd8b5a0efef6eea91d1f6a8019f77a06cc2de01155c79ae02",
        "x86_64-linux-gnu": "36e32d74e1d30e8e86b0f77f0dc9e01da58c088b64beb77c819f28bb7c99d44c",
        "aarch64-unknown-linux-gnu": "b9ec2dc21ba9f5ee738a965854a82fed3fd8c387a3b4db72c55cac24ac99c0ff",
        "x86_64-pc-windows-msvc": "1e39e5ea25cb81cfe01a0aa6e05d0019b4d6d09d3b45f68dd73f08cddfc3cfe9",
    },
}

NUSHELL_PLATFORM_ID = {
    "mac os x": {
        "aarch64": "aarch64-apple-darwin",
        "x86_64": "x86_64-apple-darwin",
    },
    "linux": {
        "aarch64": "aarch64-unknown-linux-gnu",
        "x86_64": "x86_64-linux-gnu",
    },
    "windows": {
        "x86_64": "x86_64-pc-windows-msvc",
    },
}

NUSHELL_CONSTRAINTS_MAP = {
    "aarch64-apple-darwin": [
        "@platforms//os:macos",
        "@platforms//cpu:aarch64",
    ],
    "x86_64-apple-darwin": [
        "@platforms//os:macos",
        "@platforms//cpu:x86_64",
    ],
    "x86_64-linux-gnu": [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    "aarch64-unknown-linux-gnu": [
        "@platforms//os:linux",
        "@platforms//cpu:aarch64",
    ],
    "x86_64-pc-windows-msvc": [
        "@platforms//os:windows",
        "@platforms//cpu:x86_64",
    ],
}
