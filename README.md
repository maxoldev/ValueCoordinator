<p align="center"><img src="icon.png" alt="icon" /></p>

# ValueCoordinator

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

ValueCoordinator is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ValueCoordinator'
```

## Usage

1. Add `@Coordinated` property to the first entity which "holds" the data.

```swift
class ParentViewModel {
	@Coordinated private var someValue = "Initial value"
}

```

2.  Add `@ValueProviding` property (value provider) to the second entity.
```swift
class ChildViewModel {
	@ValueProviding var someValue = "Second value"
}
```

3. Bind the value provider with the coordinated value. Now the resulting value is determined by the second entity.

```swift
parentViewModel.$someValue = childViewModel.$someValue
```

The value provider can be turned off by disabling the `isActive` flag.

Optionally you can create your own `ValueCoordinator` to customize the resulting value's determining strategy by combining values from a few providers.

4. When the value provider deinits, control over the resulting value is returned to the previous provider in the stack. In this example control is returned to the initial coordinator.

Value providers stack can be increased as much as necessary. For example, if you use navigation controller, your each next screen can be a value coordinator and define result coordinated value.

## Author

Max Sol, maxoldev@gmail.com

## License

ValueCoordinator is available under the MIT license. See the LICENSE file for more info.

<a href="https://www.flaticon.com/free-icons/coordinates" title="coordinates icons">Coordinates icons created by Freepik - Flaticon</a>