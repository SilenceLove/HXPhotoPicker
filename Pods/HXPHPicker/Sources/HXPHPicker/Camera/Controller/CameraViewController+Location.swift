//
//  CameraViewController+Location.swift
//  HXPHPicker
//
//  Created by Slience on 2021/9/1.
//

import UIKit
import CoreLocation

extension CameraViewController: CLLocationManagerDelegate {
    
    var allowLocation: Bool {
        let whenIn = Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil
        let always = Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysUsageDescription") != nil
        return config.allowLocation && (whenIn || always)
    }
    
    func startLocation() {
        if !allowLocation { return }
        if CLLocationManager.authorizationStatus() != .denied {
            locationManager.startUpdatingLocation()
            didLocation = true
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !locations.isEmpty {
            currentLocation = locations.last
        }
    }
}
