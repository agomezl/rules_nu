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

NUSHELL_OS_CONSTRAINTS_MAP = {
    "macos": "@platforms//os:macos",
    "linux": "@platforms//os:linux",
    "windows": "@platforms//os:windows",
}

NUSHELL_ARCH_CONSTRAINTS_MAP = {
    "aarch64": "@platforms//cpu:aarch64",
    "x86_64": "@platforms//cpu:x86_64",
    "amd64": "@platforms//cpu:x86_64",
}
