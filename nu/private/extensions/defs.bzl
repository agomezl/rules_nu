NUSHELL_PLATFORM_ID = {
    "macos": {
        "aarch64": "aarch64-apple-darwin",
        "x86_64": "x86_64-apple-darwin",
    },
    "linux": {
        "aarch64": "aarch64-unknown-linux-gnu",
        "x86_64": "x86_64-unknown-linux-gnu",
        "amd64": "x86_64-unknown-linux-gnu",
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
