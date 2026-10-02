load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//nu/private/extensions:templates.bzl", "PER_PLATFORM_BUILD_TEMPLATE")

def create_url(tag):
    """Creates an http_archive for a custom nu binary URL.

    Returns (repo_name, constraints) so the caller can register it in the hub.
    """
    http_archive(
        name = tag.name,
        url = tag.url,
        sha256 = tag.sha256,
        strip_prefix = tag.strip_prefix,
        build_file_content = PER_PLATFORM_BUILD_TEMPLATE.format(
            nu_path = tag.nu_path,
        ),
    )

    return tag.name, tag.exec_compatible_with
