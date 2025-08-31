//
//  MetadataTests.swift
//  EuclidTests
//
//  Created by Nick Lockwood on 04/07/2021.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

#if !os(WASI)
@testable import Euclid
import XCTest

private let projectDirectory = URL(fileURLWithPath: #file)
    .deletingLastPathComponent().deletingLastPathComponent()

private let changelogURL = projectDirectory
    .appendingPathComponent("CHANGELOG.md")

private let readmeURL = projectDirectory
    .appendingPathComponent("README.md")

private let podspecURL = projectDirectory
    .appendingPathComponent("Euclid.podspec.json")

private let projectURL = projectDirectory
    .appendingPathComponent("Euclid.xcodeproj")
    .appendingPathComponent("project.pbxproj")

private let projectVersion: String = {
    let project: String = try! String(contentsOf: projectURL)
    let start = project.range(of: "MARKETING_VERSION = ")!.upperBound
    let end = project.range(of: ";", range: start ..< project.endIndex)!.lowerBound
    return String(project[start ..< end])
}()

private let changelogTitles: [Substring] = {
    let changelog = try! String(contentsOf: changelogURL, encoding: .utf8)
    var range = changelog.startIndex ..< changelog.endIndex
    var matches = [Substring]()
    while let match = changelog.range(
        of: "## \\[[^]]+\\]\\([^)]+\\) \\([^)]+\\)",
        options: .regularExpression,
        range: range
    ) {
        matches.append(changelog[match])
        range = match.upperBound ..< changelog.endIndex
    }
    return matches
}()

class MetadataTests: XCTestCase {
    // MARK: releases

    func testBuildIsOptimized() throws {
        let project: String = try String(contentsOf: projectURL)
        XCTAssertFalse(
            project.contains("-Onone"),
            "Euclid should always be shipped with optimization enabled"
        )
    }

    func testProjectVersionMatchesChangelog() throws {
        let changelog = try String(contentsOf: changelogURL, encoding: .utf8)
        let range = try XCTUnwrap(changelog.range(of: "releases/tag/"))
        XCTAssertTrue(
            changelog[range.upperBound...].hasPrefix(projectVersion),
            "Project version \(projectVersion) does not match most recent tag in CHANGELOG.md"
        )
    }

    func testLatestVersionInChangelog() throws {
        let changelog = try String(contentsOf: changelogURL, encoding: .utf8)
        XCTAssertTrue(changelog.contains("[\(projectVersion)]"), "CHANGELOG.md does not mention latest release")
        XCTAssertTrue(
            changelog.contains("(https://github.com/nicklockwood/Euclid/releases/tag/\(projectVersion))"),
            "CHANGELOG.md does not include correct link for latest release"
        )
    }

    func testLatestVersionInReadme() throws {
        let readme = try String(contentsOf: readmeURL, encoding: .utf8)
        XCTAssertTrue(
            readme.contains("from: \"\(projectVersion)\""),
            "README.md version does not match latest release"
        )
    }

    func testLatestVersionInPodspec() throws {
        let podspec = try String(contentsOf: podspecURL, encoding: .utf8)
        XCTAssertTrue(
            podspec.contains("\"version\": \"\(projectVersion)\""),
            "Podspec version does not match latest release"
        )
        XCTAssertTrue(
            podspec.contains("\"tag\": \"\(projectVersion)\""),
            "Podspec tag does not match latest release"
        )
    }

    func testChangelogDatesAreAscending() throws {
        var lastDate: Date?
        let dateParser = DateFormatter()
        dateParser.timeZone = TimeZone(identifier: "UTC")
        dateParser.locale = Locale(identifier: "en_GB")
        dateParser.dateFormat = " (yyyy-MM-dd)"
        for title in changelogTitles {
            let dateRange = try XCTUnwrap(title.range(of: " \\([^)]+\\)$", options: .regularExpression))
            let dateString = String(title[dateRange])
            let date = try XCTUnwrap(dateParser.date(from: dateString))
            if let lastDate, date > lastDate {
                XCTFail("\(title) has newer date than subsequent version (\(date) vs \(lastDate))")
                return
            }
            lastDate = date
        }
    }
}
#endif
