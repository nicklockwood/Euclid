[![PayPal](https://img.shields.io/badge/paypal-donate-blue.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=UJWT2RWPE7VA8&source=url)
[![Build](https://github.com/nicklockwood/Euclid/actions/workflows/build.yml/badge.svg)](https://github.com/nicklockwood/Euclid/actions/workflows/build.yml)
[![Codecov](https://codecov.io/gh/nicklockwood/Euclid/graphs/badge.svg)](https://codecov.io/gh/nicklockwood/Euclid)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20|%20Mac%20|%20tvOS%20|%20Linux-lightgray.svg)]()
[![Swift 5.1](https://img.shields.io/badge/swift-5.1-red.svg?style=flat)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://opensource.org/licenses/MIT)
[![Mastodon](https://img.shields.io/badge/mastodon-@nicklockwood@mastodon.social-636dff.svg)](https://mastodon.social/@nicklockwood)

![Screenshot](Euclid.png?raw=true)

- [Introduction](#introduction)
- [Installation](#installation)
- [Contributing](#contributing)
- [Example](#example)
- [Documentation](#documentation)
- [Credits](#credits)

# Introduction

Euclid is a Swift library for creating and manipulating 3D geometry using techniques such as extruding or "lathing" 2D paths to create solid 3D shapes, and CSG (Constructive Solid Geometry) to combine or subtract those shapes from one another.

Euclid is the underlying implementation for the open source [ShapeScript scripting language](https://github.com/nicklockwood/ShapeScript) and ShapeScript [Mac](https://itunes.apple.com/app/id1441135869) and [iOS](https://apps.apple.com/app/id1606439346) apps. Anything you can build in ShapeScript can be replicated programmatically in Swift using this library.

If you would like to support the development of Euclid, please consider buying a copy of ShapeScript (the app itself is free, but there is an in-app purchase to unlock some features). You can also donate directly to the project via PayPal:

[![Donate via PayPal](https://www.paypalobjects.com/en_GB/i/btn/btn_donate_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=UJWT2RWPE7VA8&source=url)


# Installation

Euclid is packaged as a dynamic framework that you can import into your Xcode project. You can install this manually, or by using CocoaPods, Carthage, or Swift Package Manager.

**Note:** Euclid requires Xcode 14+ to build, and runs on iOS 11+ or macOS 10.13+.

To install Euclid using CocoaPods, add the following to your Podfile:

```ruby
pod 'Euclid', '~> 0.7.7'
```

To install using Carthage, add this to your Cartfile:

```ogdl
github "nicklockwood/Euclid" ~> 0.7.7
```

To install using Swift Package Manager, add this to the `dependencies:` section in your Package.swift file:

```swift
.package(url: "https://github.com/nicklockwood/Euclid.git", .upToNextMinor(from: "0.7.7")),
```


# Contributing

Feel free to open an issue in Github if you have questions about how to use the library, or think you may have found a bug.

If you wish to contribute improvements to the documentation or the code itself, that's great! But please read the [CONTRIBUTING.md](CONTRIBUTING.md) file before submitting a pull request.


# Example and ExampleVisionOS

See the included projects for examples of how Euclid can be used in conjunction with SceneKit or RealityKit to generate and render a nontrivial 3D shape. `Example` uses storyboards, is built for iOS, and runs in "Designed for iPad" mode on macOS and visionOS.
`ExampleVisionPro` uses SwiftUI and a RealityView in a volumetric window, and runs only on visionOS.


# Documentation


Full documentation for all Euclid types and functions can be found [here](https://nicklockwood.github.io/Euclid/documentation/euclid/).


# Credits

The Euclid framework is primarily the work of [Nick Lockwood](https://github.com/nicklockwood).

Special thanks go to [Evan Wallace](https://github.com/evanw/), whose [JavaScript CSG library](https://github.com/evanw/csg.js) provided the inspiration for Euclid in the first place, along with the BSP algorithm used for Euclid's CSG operations.

Thanks also go to [Joseph Heck](https://github.com/heckj) for implementing the DocC documentation, [Andy Geers](https://github.com/andygeers) for several bug fixes and improvements, and [Patrick Goley](https://twitter.com/bitsbetweenbits) who first suggested "Euclid" for the library name.

([Full list of contributors](https://github.com/nicklockwood/Euclid/graphs/contributors))

