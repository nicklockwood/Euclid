//
//  MetadataTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 04/07/2021.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

@testable import Euclid
import XCTest

private let projectDirectory = URL(fileURLWithPath: #file)
    .deletingLastPathComponent().deletingLastPathComponent()

private let changelogURL = projectDirectory
    .appendingPathComponent("CHANGELOG.md")

private let podspecURL = projectDirectory
    .appendingPathComponent("Euclid.podspec.json")

private let projectURL = projectDirectory
    .appendingPathComponent("Euclid.xcodeproj")
    .appendingPathComponent("project.pbxproj")

private let euclidVersion: String = {
    let string = try! String(contentsOf: projectURL)
    let start = string.range(of: "MARKETING_VERSION = ")!.upperBound
    let end = string.range(of: ";", range: start ..< string.endIndex)!.lowerBound
    return String(string[start ..< end])
}()

class MetadataTests: XCTestCase {
    // MARK: releases

    func testLatestVersionInChangelog() {
        let changelog = try! String(contentsOf: changelogURL, encoding: .utf8)
        XCTAssertTrue(changelog.contains("[\(euclidVersion)]"), "CHANGELOG.md does not mention latest release")
        XCTAssertTrue(
            changelog.contains("(https://github.com/nicklockwood/Euclid/releases/tag/\(euclidVersion))"),
            "CHANGELOG.md does not include correct link for latest release"
        )
    }

    func testLatestVersionInPodspec() {
        let podspec = try! String(contentsOf: podspecURL, encoding: .utf8)
        XCTAssertTrue(
            podspec.contains("\"version\": \"\(euclidVersion)\""),
            "Podspec version does not match latest release"
        )
        XCTAssertTrue(
            podspec.contains("\"tag\": \"\(euclidVersion)\""),
            "Podspec tag does not match latest release"
        )
    }
}
