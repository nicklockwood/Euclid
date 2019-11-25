//
//  Line.swift
//  Euclid
//
//  Created by Nick Lockwood on 20/11/2019.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Euclid
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

public struct LineSegment : Hashable {
    public init(point1: Vector, point2: Vector) {
        self.point1 = point1
        self.point2 = point2
    }
    
    public var point1: Vector {
        didSet { point1 = point1.quantized() }
    }
    
    public var point2: Vector {
        didSet { point2 = point2.quantized() }
    }
    
    public var direction : Vector {
        let diff = point2 - point1
        return diff.normalized()
    }
}

public struct Line : Hashable {
    public init(point: Vector, direction: Vector) {
        self.point = point
        self.direction = direction
    }
    
    public init(from: LineSegment) {
        self.point = from.point1
        self.direction = from.direction
    }
    
    public var point: Vector {
        didSet { point = point.quantized() }
    }

    public var direction: Vector {
        didSet { direction = direction.normalized() }
    }
}
