<!-- Generated with Stardoc: http://skydoc.bazel.build -->



<a id="nu_binary"></a>

## nu_binary

<pre>
load("@rules_nu//nu:rules.bzl", "nu_binary")

nu_binary(<a href="#nu_binary-name">name</a>, <a href="#nu_binary-deps">deps</a>, <a href="#nu_binary-data">data</a>, <a href="#nu_binary-cfg">cfg</a>, <a href="#nu_binary-main">main</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="nu_binary-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="nu_binary-deps"></a>deps |  Nushell module dependencies   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="nu_binary-data"></a>data |  Additional data files to include in the runfiles   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="nu_binary-cfg"></a>cfg |  Build configuration to use (target or exec)   | String | optional |  `"target"`  |
| <a id="nu_binary-main"></a>main |  The main nushell script to execute   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


