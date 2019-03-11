import XCTest

extension CSGTests {
    static let __allTests = [
        ("testIntersectionOfAdjacentBoxes", testIntersectionOfAdjacentBoxes),
        ("testIntersectionOfAdjacentSquares", testIntersectionOfAdjacentSquares),
        ("testIntersectionOfCoincidingBoxes", testIntersectionOfCoincidingBoxes),
        ("testIntersectionOfCoincidingSquares", testIntersectionOfCoincidingSquares),
        ("testIntersectionOfOverlappingBoxes", testIntersectionOfOverlappingBoxes),
        ("testIntersectionOfOverlappingSquares", testIntersectionOfOverlappingSquares),
        ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests),
        ("testSubtractAdjacentBoxes", testSubtractAdjacentBoxes),
        ("testSubtractAdjacentSquares", testSubtractAdjacentSquares),
        ("testSubtractCoincidingBoxes", testSubtractCoincidingBoxes),
        ("testSubtractCoincidingSquares", testSubtractCoincidingSquares),
        ("testSubtractOverlappingBoxes", testSubtractOverlappingBoxes),
        ("testSubtractOverlappingSquares", testSubtractOverlappingSquares),
        ("testUnionOfAdjacentBoxes", testUnionOfAdjacentBoxes),
        ("testUnionOfAdjacentSquares", testUnionOfAdjacentSquares),
        ("testUnionOfCoincidingBoxes", testUnionOfCoincidingBoxes),
        ("testUnionOfCoincidingSquares", testUnionOfCoincidingSquares),
        ("testUnionOfOverlappingBoxes", testUnionOfOverlappingBoxes),
        ("testUnionOfOverlappingSquares", testUnionOfOverlappingSquares),
    ]
}

extension PathTests {
    static let __allTests = [
        ("testClipClosedClockwiseTriangleMostlyRightOfAxis", testClipClosedClockwiseTriangleMostlyRightOfAxis),
        ("testClipClosedClockwiseTriangleToRightOfAxis", testClipClosedClockwiseTriangleToRightOfAxis),
        ("testClipClosedRectangleSpanningAxis", testClipClosedRectangleSpanningAxis),
        ("testClosedAnticlockwiseTriangleLeftOfAxis", testClosedAnticlockwiseTriangleLeftOfAxis),
        ("testConcaveClosedPathAnticlockwiseWinding", testConcaveClosedPathAnticlockwiseWinding),
        ("testConcaveClosedPathClockwiseWinding", testConcaveClosedPathClockwiseWinding),
        ("testConcaveClosedPathClockwiseWinding2", testConcaveClosedPathClockwiseWinding2),
        ("testConcaveOpenPathAnticlockwiseWinding", testConcaveOpenPathAnticlockwiseWinding),
        ("testConcaveOpenPathClockwiseWinding", testConcaveOpenPathClockwiseWinding),
        ("testConvexClosedPathAnticlockwiseWinding", testConvexClosedPathAnticlockwiseWinding),
        ("testConvexClosedPathClockwiseWinding", testConvexClosedPathClockwiseWinding),
        ("testConvexOpenPathAnticlockwiseWinding", testConvexOpenPathAnticlockwiseWinding),
        ("testConvexOpenPathClockwiseWinding", testConvexOpenPathClockwiseWinding),
        ("testEdgeVerticesForCircle", testEdgeVerticesForCircle),
        ("testEdgeVerticesForEllipse", testEdgeVerticesForEllipse),
        ("testEdgeVerticesForSemicircle", testEdgeVerticesForSemicircle),
        ("testEdgeVerticesForSharpEdgedCylinder", testEdgeVerticesForSharpEdgedCylinder),
        ("testEdgeVerticesForSmoothedClosedRect", testEdgeVerticesForSmoothedClosedRect),
        ("testEdgeVerticesForSmoothedCylinder", testEdgeVerticesForSmoothedCylinder),
        ("testEdgeVerticesForVerticalPath", testEdgeVerticesForVerticalPath),
        ("testFaceVerticesForConcaveClockwisePath", testFaceVerticesForConcaveClockwisePath),
        ("testFaceVerticesForDegenerateClosedAnticlockwisePath", testFaceVerticesForDegenerateClosedAnticlockwisePath),
        ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests),
        ("testOverlappingClosedQuad", testOverlappingClosedQuad),
        ("testOverlappingOpenQuad", testOverlappingOpenQuad),
        ("testSimpleClosedQuad", testSimpleClosedQuad),
        ("testSimpleClosedTriangle", testSimpleClosedTriangle),
        ("testSimpleLine", testSimpleLine),
        ("testSimpleOpenQuad", testSimpleOpenQuad),
        ("testSimpleOpenTriangle", testSimpleOpenTriangle),
        ("testStraightLinePathAnticlockwiseWinding", testStraightLinePathAnticlockwiseWinding),
        ("testStraightLinePathAnticlockwiseWinding2", testStraightLinePathAnticlockwiseWinding2),
        ("testStraightLinePathAnticlockwiseWinding3", testStraightLinePathAnticlockwiseWinding3),
    ]
}

extension PlaneTests {
    static let __allTests = [
        ("testConcavePolygonClockwiseWinding", testConcavePolygonClockwiseWinding),
        ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests),
    ]
}

extension PolygonTests {
    static let __allTests = [
        ("testConcaveAnticlockwisePolygonContainsPoint", testConcaveAnticlockwisePolygonContainsPoint),
        ("testConcaveAnticlockwisePolygonContainsPoint2", testConcaveAnticlockwisePolygonContainsPoint2),
        ("testConcaveAnticlockwisePolygonCorrectlyTessellated", testConcaveAnticlockwisePolygonCorrectlyTessellated),
        ("testConcaveAnticlockwisePolygonCorrectlyTriangulated", testConcaveAnticlockwisePolygonCorrectlyTriangulated),
        ("testConcavePolygonAnticlockwiseWinding", testConcavePolygonAnticlockwiseWinding),
        ("testConcavePolygonClockwiseWinding", testConcavePolygonClockwiseWinding),
        ("testConvexAnticlockwisePolygonContainsPoint", testConvexAnticlockwisePolygonContainsPoint),
        ("testConvexClockwisePolygonContainsPoint", testConvexClockwisePolygonContainsPoint),
        ("testConvexPolygonAnticlockwiseWinding", testConvexPolygonAnticlockwiseWinding),
        ("testConvexPolygonClockwiseWinding", testConvexPolygonClockwiseWinding),
        ("testDegeneratePolygonWithColinearPoints", testDegeneratePolygonWithColinearPoints),
        ("testInvertedConcaveAnticlockwisePolygonCorrectlyTessellated", testInvertedConcaveAnticlockwisePolygonCorrectlyTessellated),
        ("testInvertedConcaveAnticlockwisePolygonCorrectlyTriangulated", testInvertedConcaveAnticlockwisePolygonCorrectlyTriangulated),
        ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests),
        ("testMerge1", testMerge1),
        ("testMerge2", testMerge2),
        ("testMergeB2TAdjacentRects", testMergeB2TAdjacentRects),
        ("testMergeEdgeCase", testMergeEdgeCase),
        ("testMergeL2RAdjacentRectAndTriangle", testMergeL2RAdjacentRectAndTriangle),
        ("testMergeL2RAdjacentRects", testMergeL2RAdjacentRects),
        ("testMergeR2LAdjacentRects", testMergeR2LAdjacentRects),
        ("testMergeT2BAdjacentRects", testMergeT2BAdjacentRects),
        ("testNonDegeneratePolygonWithColinearPoints", testNonDegeneratePolygonWithColinearPoints),
    ]
}

extension ShapeTests {
    static let __allTests = [
        ("testClosedCurvedPath", testClosedCurvedPath),
        ("testClosedCurvedPathWithSharpFirstCorner", testClosedCurvedPathWithSharpFirstCorner),
        ("testClosedCurvedPathWithSharpSecondAndThirdCorner", testClosedCurvedPathWithSharpSecondAndThirdCorner),
        ("testClosedCurvedPathWithSharpSecondCorner", testClosedCurvedPathWithSharpSecondCorner),
        ("testCurveWithConsecutiveMixedTypePointsWithSamePosition", testCurveWithConsecutiveMixedTypePointsWithSamePosition),
        ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests),
        ("testSimpleCurvedPath", testSimpleCurvedPath),
        ("testSimpleCurveEndedPath", testSimpleCurveEndedPath),
    ]
}

extension TransformTests {
    static let __allTests = [
        ("testAxisAngleRotation1", testAxisAngleRotation1),
        ("testAxisAngleRotation2", testAxisAngleRotation2),
        ("testAxisAngleRotation3", testAxisAngleRotation3),
        ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests),
        ("testPitch", testPitch),
        ("testRoll", testRoll),
        ("testRotationMultipliedByScale", testRotationMultipliedByScale),
        ("testRotationMultipliedByTranslation", testRotationMultipliedByTranslation),
        ("testScaleMultipliedByRotation", testScaleMultipliedByRotation),
        ("testTransformVector", testTransformVector),
        ("testTranslationMultipliedByRotation", testTranslationMultipliedByRotation),
        ("testTranslationMultipliedByScale", testTranslationMultipliedByScale),
        ("testYaw", testYaw),
    ]
}

extension UtilityTests {
    static let __allTests = [
        ("testColinearPointsDontPreventConvexness", testColinearPointsDontPreventConvexness),
        ("testConvexnessResultNotAffectedByTranslation", testConvexnessResultNotAffectedByTranslation),
        ("testDegenerateColinearVertices", testDegenerateColinearVertices),
        ("testDegenerateVerticesWithZeroLengthEdge", testDegenerateVerticesWithZeroLengthEdge),
        ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests),
        ("testNonDegenerateColinearVertices", testNonDegenerateColinearVertices),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CSGTests.__allTests),
        testCase(PathTests.__allTests),
        testCase(PlaneTests.__allTests),
        testCase(PolygonTests.__allTests),
        testCase(ShapeTests.__allTests),
        testCase(TransformTests.__allTests),
        testCase(UtilityTests.__allTests),
    ]
}
#endif
