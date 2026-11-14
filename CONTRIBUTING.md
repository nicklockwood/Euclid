# Contributing to Euclid

Are you interested in contributing to Euclid? Fantastic!

Here's what you need to know:

## Versioning

Euclid follows the principles of [Semantic Versioning](http://semver.org/spec/v2.0.0.html) (semver), however since Euclid is still pre-1.0, the rules are a little less strict. In general, 0.0.x releases are for bug fixes and non-breaking changes, and 0.x.0 releases are for breaking changes.

Since Euclid is an asset creation tool as well as a framework, "breaking changes" refers to the generated geometry as well as the API. Changes to the way geometry is generated or tessellated by a given function are considered to be breaking, even if they do not affect the framework API.

## Your First Pull Request

Making your first pull request can be scary. If you have trouble with any of the contribution rules, **make a pull request anyway**. A PR is the start of a process not the end of it.

All types of PR are welcome, but please do read these guidelines carefully to avoid wasting your time and ours. If you are planning something big, or which might be controversial, it's a great idea to create an issue first to discuss it before writing a lot of code.

Types of PR:

* Documentation fixes - if you've found a typo, or incorrect comment, either in the README or a code comment, feel free to create a PR directly against the **main** branch.

* Minor code fixes - a typo in a method name or a trivial bug fix should be made against the **develop** branch.

* Major code changes - significant refactors or new functionality should usually be raised as an issue first to avoid wasted effort on a PR that's unlikely to land. This is mainly for your own sake, not ours, so if you prefer to make suggestions in code form then that's fine too. As with fixes, PRs should be made against the **develop** branch.

## Copyright and Licensing

Any new source files that you add should include the standard license header used in all the existing files. You may include your own name as the author for files that you created or replaced.

By contributing code to Euclid, you are implicitly agreeing to license it under the terms described in the LICENSE.md file. Please do not submit code that you did not write or are not authorized to redistribute.

Inclusion of 3rd party frameworks is **not** permitted, regardless of the license. Small sections of code copied from somewhere else *may* be acceptable, provided that the terms of the original license are compatible with Euclid's LICENSE.md, and that you include a comment linking back to the source.

## Code Style

Euclid's source code mostly follows the [Ray Wenderlich Style Guide](https://github.com/raywenderlich/swift-style-guide) very closely with the following exception:

- Use the Xcode default of 4 spaces for indentation.

## Documentation

Code should be commented, but not excessively. In general, comments should follow the principle of *why, not what*, but it's acceptable to use "obvious" comments as headings to break up large blocks of code. Public methods and classes should be commented using the `///` headerdoc style.

When making user-facing changes, please update the README.md file if applicable. There is no need to update CHANGELOG.md or bump the version number.

## Tests

All significant code changes should be accompanied by a test.  

Tests are run automatically on all pull requests, branches and tags. These are the same tests that run in Xcode at development time.

### Color import/export regressions

Run the shared swatch, gradient, material and texture fixtures with:

```sh
swift test --filter ColorImportExportRegressionTests
```

These tests compare numeric values, geometry and material assignments instead of entire files. Exporter-generated IDs, vertex ordering and binary encodings can vary between OS versions. Selected ASCII and binary fields are checked independently of Euclid's reader so matching reader/writer errors cannot cancel each other out. `PLYImportTests` and `ModelIOExportTests` provide additional fixed-input and adapter coverage.

| Format/path | Checks and intentional limitations |
| --- | --- |
| ASCII PLY | Material and vertex RGBA, stored bytes, quantization, gradient and linear-light tint multiplication |
| Native OBJ | Stored vertex RGB and round trip. This writer does not emit vertex alpha or material libraries |
| Platform OBJ | Material RGB/opacity and assignment, vertex RGB round trip, texture pixels, alpha and Model I/O texture connections. Independent OBJ/MTL input through both platform loaders |
| Binary STL | Stored facet RGB and round trip with 5-bit tolerance. No alpha or vertex colors |
| ASCII STL, OFF | Geometry round trip. Euclid's writers do not preserve appearance in these formats |
| SCN, SCNZ | Material and vertex RGBA round trips, combined vertex tint/material opacity, and rendered texture × tint × vertex color/alpha round trips |
| DAE | SceneKit serialization of linear vertex RGB, material RGBA and material/effect bindings in macOS XML. Binary SceneKit representation round trip on iOS |
| USD, USDA, USDC | Material values and assignment. USDA/USDC vertex round trips. independent USDA shader/displayColor values and texture files |
| USDZ | Material values and assignment through Euclid's SceneKit fallback |
| Alembic | Geometry smoke test. Apple's exporter does not preserve appearance |

The fixtures include black/white, asymmetric RGB midtones, independent opacity values, fully transparent colors and a nonuniform vertex gradient. Colors are compared using Euclid's interoperability conventions: sRGB for OBJ/PLY, default linear Rec.709 for USD, and unconverted facet values for STL. OBJ/PLY sRGB handling is a convention, not a universal format requirement. The Collada test checks that SceneKit serializes the linear vertex values supplied by Euclid. it does not establish a color-space requirement for all Collada files. Alpha is never gamma converted. Texture comparisons use premultiplied sRGB pixels with a one-byte rounding tolerance and asymmetric rows to detect vertical flips.

Platform exports prefer SceneKit, falling back to Model I/O when needed. The Model I/O material bridge preserves texture bytes and opacity. Numeric material colors are restored on the export copy. OBJ output also restores diffuse textures and numeric MTL values altered by the platform writer.

OBJ, USD, USDA and USDC tests also inspect the base-color texture connected to imported Model I/O submeshes. OBJ texture tests cover sRGB, linear sRGB and Display P3 input profiles, comparing their appearance in sRGB. The SCN/SCNZ combined-appearance test renders an unlit textured surface before and after export with independent vertex alpha, multiply tint and material opacity. It compares center pixels under identical conditions rather than entire screenshots. These checks do not establish compatibility with every external renderer.

Independent USD and Collada fixtures are hand-authored in `Tests/ColorImportFixtures.swift`, including scalar colors, opacity and texture connections. Rendered comparisons use an unlit reference with known color and opacity to separate these channels from lighting and BRDF differences. The USD texture fixture explicitly declares sRGB for color and raw for its grayscale opacity map, following the [USD Preview Surface specification](https://openusd.org/release/spec_usdpreviewsurface.html). The OBJ fixture uses the default luminance channel for `map_d`, as specified in the [Wavefront material reference](https://www.fileformat.info/format/material/).

The macOS CI jobs run the full suite. A separate iOS simulator job runs the color regression suite and the Model I/O, OBJ opacity and PLY adapter tests. Renderer checks skip when no Metal device is available. macOS Collada checks inspect XML directly. The platform's XPC loader can reject exported Collada files, so these assertions do not imply a successful Collada reimport. Independent XML import tests report a skip for the observed macOS XPC failure or the nil-result failure on iOS. Binary SceneKit DAE round trips remain tested separately.

#### Color-space contracts and limits

[OpenUSD defaults to linear Rec.709](https://openusd.org/release/user_guides/color_user_guide.html#default-color-space), but allows color-space metadata on attributes and prims. `testUSDMaterialColorSpaceMetadata` and `testUSDTextureColorSpaceMetadata` vary attribute metadata, shader and ancestor `ColorSpaceAPI` declarations, inheritance overrides, and Preview Surface `sourceColorSpace` inputs. Their twenty hand-authored cases include linear Rec.709, sRGB, P3, ACEScg and raw data. Expected colors come from independent CoreGraphics conversions. Comparisons inspect imported values and render both the original shading model and an unlit equivalent. On macOS, `/usr/bin/usdcat`, when available, also converts the fixtures to USDC without re-exporting them through the loader being tested.

The audit records raw material values, color-space tags, Model I/O property names and rendered pixels in JSON attachments. `EUCLID_COLOR_REGRESSION_OUTPUT` also retains the reports and generated fixtures on disk. Known platform discrepancies are expected failures, not successful preservation checks. `EUCLID_COLOR_REGRESSION_STRICT=1` exposes them as ordinary failures.

On macOS 26.6.2 and the iOS 26.5 simulator, the tested declarations do not distinguish imported results. SceneKit returns the same RGB numbers tagged as linear Display P3, even for default Rec.709, sRGB and ACEScg inputs. Model I/O returns the same untagged float3 values. Euclid's linear-default conversion works for Rec.709 but cannot infer a different authored space from those values. Its material properties do not expose the tested declarations. The native `SCNMaterial(mdlMaterial:)` bridge additionally changes numeric diffuse values, so its rendered result is recorded separately from Euclid's direct Model I/O color conversion.

For the sRGB-tagged PNG connected to diffuse color, both loaders retain the sRGB appearance even when USD declares `raw`, `data`, P3 or ACEScg. Identical behavior occurs in the original shading model and the unlit comparison, and in USDA and USDC on macOS. This observation concerns color-texture connections. it does not establish incorrect decoding of opacity or PBR data channels. Cases that happen to match a loader's fixed interpretation do not demonstrate metadata support.

Euclid's format-based fallback does not resolve USD color-space metadata. Declared CGColor profiles supplied directly to the material bridge are respected, but reliable handling of authored USD spaces requires access to the USD declarations and their inheritance before Apple discards that information. The audit adds no production conversion heuristic or USD dependency.

The [OBJ-to-USD interoperability guidance](https://docs.omniverse.nvidia.com/usd/latest/technical_reference/conceptual_data_mapping/obj-usd-concept-mapping.html) describes MTL colors as typically sRGB. [PLY defines extensible vertex properties](https://sites.cc.gatech.edu/projects/large_models/ply.html), without establishing the same color-management contract as USD. The [Collada specification](https://www.khronos.org/files/collada_spec_1_4.pdf) does not justify treating every linear vertex-color export as a defect.

[PNG stores unassociated alpha](https://www.w3.org/TR/png/#6AlphaRepresentation). The tested Image I/O and Model I/O paths correctly unpremultiply the supplied premultiplied pixels when writing PNG. Euclid must not unpremultiply those pixels a second time. The retained texture tests verify this behavior, not an Image I/O color-conversion defect.

Material color normalization is restricted to the inspected file families and RGB color semantics (base color, emission and specular). Other formats retain the Model I/O adapter's default representation without format-specific material rewriting. Opacity, roughness, normals and other data properties are not gamma converted.

#### Inspecting exported files

```sh
EUCLID_COLOR_REGRESSION_OUTPUT=/tmp/euclid-colors \
  swift test --filter ColorImportExportRegressionTests
```

Each test creates a uniquely named directory containing its exports, sidecar files, an `expected-swatches.json` description, and (where SceneKit export is available) a `reference.scn` scene. Swatches run left-to-right in rows of three. The tinted-gradient and textured-cube cases use different geometry from the swatch reference. Compare these files in Quick Look or another application. Identical lighting is not guaranteed across viewers. By default temporary files are deleted after each test. Tests never overwrite checked-in fixtures or automatically approve new baselines. In Xcode, set the same environment variable in the test scheme to retain files in a location writable by the test process.

SceneKit's OBJ import converts legacy material values into a physically based material. Its diffuse RGB may differ from the authored `Kd`. The compatibility test compares this result with Apple's direct `SCNMaterial(mdlMaterial:)` bridge rather than treating the difference as a color-management defect. Model I/O's raw material values are still checked against the independent MTL input.

OBJ file import corrects dissolve-map channel handling in both the SceneKit path and the Model I/O fallback for ordinary 8-bit grayscale and RGB images. The MTL `map_d` declaration selects luminance by default, or an explicit red, green, blue or matte/alpha channel with `-imfchan`. Scalar `d` (or inverse `Tr`) is applied once, including when combined with a map. RGB/luminance samples are moved into an alpha mask without gamma or profile conversion. Diffuse textures and explicit-alpha image contents are preserved. The Model I/O fallback normalizes opacity before material callbacks into a single-channel texture, baking the scalar with eight-bit rounding. Its sampler settings and orientation are preserved. Euclid's SceneKit material bridge converts single-channel opacity to an alpha mask. RealityKit consumes the raw scalar texture. Existing `Mesh(MDLAsset)` imports retain the asset's materials, since an arbitrary asset does not supply the original OBJ/MTL channel declarations. Unsupported image layouts and modifiers such as `-mm`, depth channels and halo dissolve remain with the platform loader. `OBJOpacityTests` covers sidecar resolution, channel selection, profiles, premultiplication, byte ordering and row padding. Rendered tests verify channel selection and scalar multiplication through both loading paths. Model I/O tests also check callback-visible data, repeated normalization, sampler settings and RealityKit GPU texture bytes.

USD file export splits material groups into separate meshes because Model I/O otherwise binds only the last submesh material. The USD/USDA/USDC material-assignment assertions are unconditional. Mesh bounds, surface area, normals, UVs and custom material callbacks have additional coverage. The public `MDLAsset` initializer retains its single-mesh representation.

#### Known failures

The suite retains desired-value assertions for the following observed problems using narrowly scoped, non-strict `XCTExpectFailure` blocks:

- SceneKit tags the independent USD fixture's default linear Rec.709 constant material color as linear Display P3, shifting its rendered color. The same fixture with explicit sRGB color and raw opacity textures renders correctly.
- USD displayColor is exported, but the SceneKit import path does not restore it as vertex color. Model I/O also omits vertex alpha.
- The Model I/O Alembic polygon-topology round trip reports an empty bounding box.

These are documented defects, not approved output baselines. Geometry validation, authored USD values and unaffected channels remain ordinary assertions. Non-strict expectations allow platform versions that already work to pass. Remove an expectation when its underlying issue is resolved. To expose all known defects as ordinary failures when working on a fix:

```sh
EUCLID_COLOR_REGRESSION_STRICT=1 \
  swift test --filter ColorImportExportRegressionTests
```

No exporter behavior is changed by this suite. Platform-specific checks are conditionally compiled. Unavailable Model I/O exporters are reported as skipped tests.

## Code of Conduct

There will be zero tolerance for rudeness or bullying. If you think somebody else's comment or pull request is stupid, keep it to yourself. If you are frustrated because your issue or pull request isn't getting the attention it deserves, feel free to post a comment like "any update on this?", but remember that we are all busy, and other peoples' priorities don't necessarily match yours.

Abusive contributors will be blocked and/or reported, regardless of how valuable their code contributions may be.
