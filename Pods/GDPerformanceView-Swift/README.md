# GDPerformanceView-Swift
Shows FPS, CPU and memory usage, device model, app and iOS versions above the status bar and report FPS, CPU and memory usage via delegate.

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-brightgreen.svg)](https://github.com/Carthage/Carthage) 
[![Pod Version](https://img.shields.io/badge/Pod-2.1.1-6193DF.svg)](https://cocoapods.org/)
![Swift Version](https://img.shields.io/badge/xCode-12.0+-blue.svg)
![Swift Version](https://img.shields.io/badge/iOS-9.0+-blue.svg) 
![Swift Version](https://img.shields.io/badge/Swift-5.0+-orange.svg)
![Plaform](https://img.shields.io/badge/Platform-iOS-lightgrey.svg)
![License MIT](https://img.shields.io/badge/License-MIT-lightgrey.svg) 

![Alt text](https://github.com/dani-gavrilov/GDPerformanceView-Swift/blob/master/performance_view.PNG?raw=true "Example PNG")
![Alt text](https://github.com/dani-gavrilov/GDPerformanceView-Swift/blob/master/performance_view_2.PNG?raw=true "Example PNG")
![Alt text](https://github.com/dani-gavrilov/GDPerformanceView-Swift/blob/master/performance_view_3.PNG?raw=true "Example PNG")
![Alt text](https://github.com/dani-gavrilov/GDPerformanceView-Swift/blob/master/performance_view_4.PNG?raw=true "Example PNG")

## Installation
Simply add GDPerformanceMonitoring folder with files to your project, or use CocoaPods.

#### Carthage
Create a `Cartfile` that lists the framework and run `carthage update`. Follow the [instructions](https://github.com/Carthage/Carthage#if-youre-building-for-ios) to add `$(SRCROOT)/Carthage/Build/iOS/GDPerformanceView.framework` to an iOS project.

```ruby
github "dani-gavrilov/GDPerformanceView-Swift" ~> 2.1.1
```
Don't forget to import GDPerformanceView by adding: 

```swift
import GDPerformanceView
```

#### CocoaPods
You can use [CocoaPods](http://cocoapods.org/) to install `GDPerformanceView` by adding it to your `Podfile`:

```ruby
platform :ios, '8.0'
use_frameworks!

target 'project_name' do
	pod 'GDPerformanceView-Swift', '~> 2.1.1'
end
```
Don't forget to import GDPerformanceView by adding: 

```swift
import GDPerformanceView_Swift
```

## Usage example

Simply start monitoring. Performance view will be added above the status bar automatically.
Also, you can configure appearance as you like or just hide the monitoring view and use its delegate.

You can find example projects [here](https://github.com/dani-gavrilov/GDPerformanceViewExamples).

#### Start monitoring

By default, monitoring is paused. Call the following command to start or resume monitoring:

```swift
PerformanceMonitor.shared().start()
```
or

```swift
self.performanceView = PerformanceMonitor()
self.performanceView?. start()
```
This won't show the monitoring view if it was hidden previously. To show it call the following command:

```swift
self.performanceView?.show()
```

#### Pause monitoring

Call the following command to pause monitoring:

```swift
self.performanceView?.pause()
```

This won't hide the monitoring view. To hide it call the following command:

```swift
self.performanceView?.hide()
```

#### Displayed information

You can change displayed information by changing options of the performance monitor:

```swift
self.performanceView?.performanceViewConfigurator.options = .all
```
You can choose from:

* performance - CPU usage and FPS.
* memory - Memory usage.
* application - Application version with build number.
* device - Device model.
* system - System name with version.

Also you can mix them, but order doesn't matter:

```swift
self.performanceView?.performanceViewConfigurator.options = [.performance, .application, .system]
```
By default, set of [.performance, .application, .system] options is used.

You can also add your custom information by using:

```swift
self.performanceView?.performanceViewConfigurator.userInfo = .custom(string: "Launch date \(Date())")
```
Keep in mind that custom string will not automatically fit the screen, use `\n` if it is too long.

#### Appearance

You can change monitoring view appearance by changing style of the performance monitor:

Call the following command to change output information:

```swift
self.performanceView?.performanceViewConfigurator.style = .dark
```

You can choose from:

* dark - Black background, white text.
* light - White background, black text.
* custom - You can set background color, border color, border width, corner radius, text color and font.

By default, dark style is used.

Also you can override prefersStatusBarHidden and preferredStatusBarStyle to match your expectations:

```swift
self.performanceView?.statusBarConfigurator.statusBarHidden = false
self.performanceView?.statusBarConfigurator.statusBarStyle = .lightContent
```

#### Interactions

You can interact with performance view via gesture recognizers. Add them by using:

```swift
self.performanceView?.performanceViewConfigurator.interactors = [tapGesture, swipeGesture]
```
If interactors is nil or empty `point(inside:with:)` of the view will return false to make all touches pass underneath. So to remove interactors just call the following command:

```swift
self.performanceView?.performanceViewConfigurator.interactors = nil
```
By default, interactors are nil.

#### Delegate

Set the delegate and implement its method:

```swift
self.performanceView?.delegate = self
```

```swift
func performanceMonitor(didReport performanceReport: PerformanceReport) {
	print(performanceReport.cpuUsage, performanceReport.fps, performanceReport.memoryUsage.used, performanceReport.memoryUsage.total)
}
```

## Requirements
- iOS 9.0+
- xCode 12.0+

## Donations

Wanna say thanks? You can do it using [Patreon](https://www.patreon.com/dani_gavrilov).

## Meta

Daniil Gavrilov - [VK](https://vk.com/dani_gavrilov) - [FB](https://facebook.com/danigavrilov)

I will be pleased to know that your project uses this framework. You can send a link to your project in App Store to my email - [daniilmbox@gmail.com](mailto:daniilmbox@gmail.com).

## License

GDPerformanceView is available under the MIT license. See the LICENSE file for more info.

