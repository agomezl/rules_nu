# Nushell releases database with platform-specific SHA256 hashes
# See: https://github.com/nushell/nushell/releases
NUSHELL_RELEASES = {
    "0.114.0": {
        "aarch64-apple-darwin": "c98f7deedd41023fe6dc4567abb368c9442bda62989b91e179e095cbb457ce58",
        "x86_64-apple-darwin": "dd1f92f524794fab8b4f20287d84038fb08865f9a7c5a5c71461d44ed1c5c7f8",
        "x86_64-unknown-linux-gnu": "3896777ebf3678f6d41736a5e995ba8360b338eb73c713254fc024e08ec72289",
        "aarch64-unknown-linux-gnu": "280163b9a2b3c54e45ded348b577a569cdf2a292e8fe9d77fe02405c3415c8c3",
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
        "x86_64": "x86_64-unknown-linux-gnu",
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
    "x86_64-unknown-linux-gnu": [
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
