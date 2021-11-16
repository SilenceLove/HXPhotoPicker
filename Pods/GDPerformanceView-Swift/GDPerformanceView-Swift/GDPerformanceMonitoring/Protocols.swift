//
// Copyright © 2017 Gavrilov Daniil
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import UIKit

/// Memory usage tuple. Contains used and total memory in bytes.
public typealias MemoryUsage = (used: UInt64, total: UInt64)

/// Performance report tuple. Contains CPU usage in percentages, FPS and memory usage.
public typealias PerformanceReport = (cpuUsage: Double, fps: Int, memoryUsage: MemoryUsage)

/// Performance monitor delegate. Gets called on the main thread.
public protocol PerformanceMonitorDelegate: class {
    /// Reports monitoring information to the receiver.
    ///
    /// - Parameters:
    ///   - performanceReport: Performance report tuple. Contains CPU usage in percentages, FPS and memory usage.
    func performanceMonitor(didReport performanceReport: PerformanceReport)
}

public protocol PerformanceViewConfigurator {
    var options: PerformanceMonitor.DisplayOptions { get set }
    var userInfo: PerformanceMonitor.UserInfo { get set }
    var style: PerformanceMonitor.Style { get set }
    var interactors: [UIGestureRecognizer]? { get set }
}

public protocol StatusBarConfigurator {
    var statusBarHidden: Bool { get set }
    var statusBarStyle: UIStatusBarStyle { get set }
}
