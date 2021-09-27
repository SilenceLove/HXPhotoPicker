//
//  DeviceOrientationHelper.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/30.
//

import UIKit
import CoreMotion

final class DeviceOrientationHelper {
    // Singleton is recommended because an app should create only a single instance of the CMMotionManager class.
    static let shared = DeviceOrientationHelper()
    
    private let motionManager: CMMotionManager
    private let queue: OperationQueue
    
    typealias DeviceOrientationHandler = ((_ deviceOrientation: UIDeviceOrientation) -> Void)?
    private var deviceOrientationAction: DeviceOrientationHandler?
    
    public var currentDeviceOrientation: UIDeviceOrientation = .portrait

    // Smallers values makes it much sensitive to detect an orientation change. [0 to 1]
    private let motionLimit: Double = 0.6
    
    private var isStarting: Bool = false
    
    init() {
        motionManager = CMMotionManager()
        // Specify an update interval in seconds, personally found this value provides a good UX
        motionManager.accelerometerUpdateInterval = 0.2
        
        queue = OperationQueue()
    }
    
    public func startDeviceOrientationNotifier(
        with handler: DeviceOrientationHandler? = nil
    ) {
        if isStarting {
            return
        }
        if let handler = handler {
            self.deviceOrientationAction = handler
        }
        isStarting = true
        //  Using main queue is not recommended.
        // So create new operation queue and pass it to startAccelerometerUpdatesToQueue.
        //  Dispatch U/I code to main thread using dispach_async in the handler.
        
        motionManager.startAccelerometerUpdates(to: queue) { (data, _) in
            if let accelerometerData = data {
                var newDeviceOrientation: UIDeviceOrientation?
                
                if accelerometerData.acceleration.x >= self.motionLimit {
                    newDeviceOrientation = .landscapeRight
                } else if accelerometerData.acceleration.x <= -self.motionLimit {
                    newDeviceOrientation = .landscapeLeft
                } else if accelerometerData.acceleration.y <= -self.motionLimit {
                    newDeviceOrientation = .portrait
                } else if accelerometerData.acceleration.y >= self.motionLimit {
                    newDeviceOrientation = .portraitUpsideDown
                } else {
                    return
                }
                
                // Only if a different orientation is detect, execute handler
                if let newDeviceOrientation = newDeviceOrientation,
                    newDeviceOrientation != self.currentDeviceOrientation {
                    self.currentDeviceOrientation = newDeviceOrientation
                    if let deviceOrientationHandler = self.deviceOrientationAction {
                        DispatchQueue.main.async {
                            deviceOrientationHandler!(self.currentDeviceOrientation)
                        }
                    }
                }
            }
        }
    }
    
    public func stopDeviceOrientationNotifier() {
        motionManager.stopAccelerometerUpdates()
        isStarting = false
    }
}
