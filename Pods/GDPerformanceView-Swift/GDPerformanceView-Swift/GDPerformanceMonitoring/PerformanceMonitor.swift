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

// MARK: Class Definition

public class PerformanceMonitor {
    
    // MARK: Enums
    
    public enum Style {
        case dark
        case light
        case custom(backgroundColor: UIColor, borderColor: UIColor, borderWidth: CGFloat, cornerRadius: CGFloat, textColor: UIColor, font: UIFont)
    }
    
    public enum UserInfo {
        case none
        case custom(string: String)
    }
    
    private enum States {
        case started
        case paused
        case pausedBySystem
    }
    
    // MARK: Structs
    
    public struct DisplayOptions: OptionSet {
        public let rawValue: Int
        
        /// CPU usage and FPS.
        public static let performance = DisplayOptions(rawValue: 1 << 0)
        
        /// Memory usage.
        public static let memory = DisplayOptions(rawValue: 1 << 1)
        
        /// Application version with build number.
        public static let application = DisplayOptions(rawValue: 1 << 2)
        
        /// Device model.
        public static let device = DisplayOptions(rawValue: 1 << 3)
        
        /// System name with version.
        public static let system = DisplayOptions(rawValue: 1 << 4)
        
        /// Default dispaly options - CPU usage and FPS, application version with build number and system name with version.
        public static let `default`: DisplayOptions = [.performance, .application, .system]
        
        /// All dispaly options.
        public static let all: DisplayOptions = [.performance, .memory, .application, .device, .system]
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    // MARK: Public Properties
    
    public weak var delegate: PerformanceMonitorDelegate?
    
    public var performanceViewConfigurator: PerformanceViewConfigurator {
        get {
            return self.performanceView
        }
        set { }
    }
    
    public var statusBarConfigurator: StatusBarConfigurator {
        get {
            guard let rootViewController = self.performanceView.rootViewController as? WindowViewController else {
                fatalError("Root view controller must be a kind of WindowViewController.")
            }
            return rootViewController
        }
        set { }
    }
    
    // MARK: Private Properties
    
    private static var sharedPerformanceMonitor: PerformanceMonitor!
    
    private let performanceView = PerformanceView()
    private let performanceCalculator = PerformanceCalculator()
    private var state = States.paused
    
    // MARK: Init Methods & Superclass Overriders
    
    /// Initializes performance monitor with parameters.
    ///
    /// - Parameters:
    ///   - options: Display options. Allows to change the format of the displayed information.
    ///   - style: Style. Allows to change the appearance of the displayed information.
    ///   - delegate: Performance monitor output.
    required public init(options: DisplayOptions = .default, style: Style = .dark, delegate: PerformanceMonitorDelegate? = nil) {
        self.performanceView.options = options
        self.performanceView.style = style
        
        self.performanceCalculator.onReport = { [weak self] (performanceReport) in
            DispatchQueue.main.async {
                self?.apply(performanceReport: performanceReport)
            }
        }
        
        self.delegate = delegate
        self.subscribeToNotifications()
    }
    
    /// Initializes performance monitor singleton with default properties.
    ///
    /// - Returns: Performance monitor singleton.
    public class func shared() -> PerformanceMonitor {
        if self.sharedPerformanceMonitor == nil {
            self.sharedPerformanceMonitor = PerformanceMonitor()
        }
        return self.sharedPerformanceMonitor
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: Public Methods

public extension PerformanceMonitor {
    func hide() {
        self.performanceView.hide()
    }
    
    func show() {
        self.performanceView.show()
    }
    
    func start() {
        switch self.state {
        case .started:
            return
        case .paused, .pausedBySystem:
            self.state = .started
            self.performanceCalculator.start()
        }
    }
    
    func pause() {
        switch self.state {
        case .paused:
            return
        case .started, .pausedBySystem:
            self.state = .paused
            self.performanceCalculator.pause()
        }
    }
}

// MARK: Notifications & Observers

private extension PerformanceMonitor {
    func applicationWillEnterForegroundNotification(notification: Notification) {
        switch self.state {
        case .started, .paused:
            return
        case .pausedBySystem:
            self.state = .started
            self.performanceCalculator.start()
        }
    }
    
    func applicationDidEnterBackgroundNotification(notification: Notification) {
        switch self.state {
        case .paused, .pausedBySystem:
            return
        case .started:
            self.state = .pausedBySystem
            self.performanceCalculator.pause()
        }
    }
}

// MARK: Configurations

private extension PerformanceMonitor {
    func subscribeToNotifications() {
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (notification) in
            self?.applicationWillEnterForegroundNotification(notification: notification)
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] (notification) in
            self?.applicationDidEnterBackgroundNotification(notification: notification)
        }
    }
}

// MARK: Support Methods

private extension PerformanceMonitor {
    func apply(performanceReport: PerformanceReport) {
        self.performanceView.update(withPerformanceReport: performanceReport)
        self.delegate?.performanceMonitor(didReport: performanceReport)
    }
}
