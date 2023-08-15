//
//  ValueCoordinator
//
//  Created by Max Sol on 05/06/2022.
//

@propertyWrapper
public class ValueProviding<Value> {
    
    private let valueProvider: ValueProvider<Value>
    private let valueProviderHolder: ScopedValueProviderHolder<Value>

    private var valueCoordinator: ValueCoordinator<Value>? {
        didSet {
            guard let valueCoordinator else {
                valueProvider.removeFromValueCoordinator()
                return
            }
            valueProvider.appendToValueCoordinator(valueCoordinator)
        }
    }
    
    public var isActive: Bool {
        get { valueProvider.isActive }
        
        set {
            valueProvider.isActive = newValue
            valueProvider.requestUpdateFromCoordinator()
        }
    }

    public var wrappedValue: Value {
        didSet {
            valueProvider.value = wrappedValue
        }
    }

    public var projectedValue: ValueCoordinator<Value>? {
        get { valueCoordinator }
        set { valueCoordinator = newValue }
    }

    public init(wrappedValue: Value, isActive: Bool = true, valueCoordinator: ValueCoordinator<Value>? = nil) {
        self.wrappedValue = wrappedValue
        
        valueProvider = ValueProvider<Value>(value: wrappedValue, isActive: isActive)
        valueProviderHolder = ScopedValueProviderHolder(valueProvider)
        
        if let valueCoordinator = valueCoordinator {
            valueProvider.appendToValueCoordinator(valueCoordinator)
        }
    }

}

/// Provider holder which removes its provider from the coordinator on `deinit`
public class ScopedValueProviderHolder<Value> {

    public private(set) var valueProvider: ValueProvider<Value>!
    
    public init(_ provider: ValueProvider<Value>) {
        self.valueProvider = provider
    }
    
    deinit {
        valueProvider.removeFromValueCoordinator()
    }
    
}

public class ValueProvider<Value> {
    
    /// Provided value
    public var value: Value {
        didSet {
            if valueCoordinator != nil && isActive {
                requestUpdateFromCoordinator()
            }
        }
    }
    
    /// Set `false` to ignore value from this provider
    public var isActive = true
    
    fileprivate weak var valueCoordinator: ValueCoordinator<Value>?

    public init(value: Value, isActive: Bool = true) {
        self.value = value
        self.isActive = isActive
    }

    public func appendToValueCoordinator(_ valueCoordinator: ValueCoordinator<Value>) {
        precondition(self.valueCoordinator == nil)
        
        self.valueCoordinator = valueCoordinator
        valueCoordinator.append(provider: self)
    }

    public func removeFromValueCoordinator() {
        valueCoordinator?.remove(provider: self)
        valueCoordinator = nil
    }

    public func requestUpdateFromCoordinator() {
        guard isActive else {
            return
        }
        guard let valueCoordinator else {
            print("\(ValueCoordinator<Value>.self) is nil")
            return
        }
        valueCoordinator.update(requestedByProvider: self)
    }
    
}

/// Property wrapper which allows you to use a coordinated property as an ordinary one.
///
/// To access the underlying coordinator use projectedValue via `$` syntax (`$someVariable`)
@propertyWrapper
public class Coordinated<Value> {
    
    private let coordinator: ValueCoordinator<Value>

    public var wrappedValue: Value {
        get { coordinator.value }
        set { coordinator.value = newValue }
    }
    
    public var projectedValue: ValueCoordinator<Value> {
        coordinator
    }
    
    public init(wrappedValue: Value, onUpdate: ((Value) -> Void)? = nil) {
        coordinator = ValueCoordinator<Value>(rootValue: wrappedValue, onUpdate: onUpdate)
    }

    public init(coordinator: ValueCoordinator<Value>) {
        self.coordinator = coordinator
    }

}

/// Allows delegate property value providing.
///
/// Use `append` to add provider to the stack and `remove` to remove it from the stack.
open class ValueCoordinator<Value> {
    
    public var providers = [ValueProvider<Value>]()
    public var onUpdate: ((Value) -> Void)? {
        didSet {
            update()
        }
    }
    public private(set) var rootValue: Value

    private let lock = NSRecursiveLock()

    public init(rootValue: Value, onUpdate: ((Value) -> Void)? = nil) {
        self.rootValue = rootValue
        self.onUpdate = onUpdate
    }

    open var value: Value {
        get {
            let lastActiveProviderValue = lastActiveProvider?.value
            let resultValue = lastActiveProviderValue ?? rootValue
            return resultValue
        }
        
        set {
            rootValue = newValue

            if !hasActiveProviders {
                update()
            }
        }
    }

    public func append(provider: ValueProvider<Value>) {
        try? lock.locking {
            providers.append(provider)

            if provider.isActive {
                update()
            }
        }
    }

    public func remove(provider: ValueProvider<Value>) {
        try? lock.locking {
            guard let index = providers.firstIndex(where: { $0 === provider }) else {
                let msg = "You're trying to remove a provider not belonging to this \(ValueCoordinator.self)"
                assertionFailure(msg)
                return
            }
            providers.remove(at: index)

            if provider.isActive {
                update()
            }
        }
    }

    open func update(requestedByProvider provider: ValueProvider<Value>) {
        guard (try? lock.locking({
            guard let index = providers.firstIndex(where: { $0 === provider }) else {
                let msg = "You're trying to request an update by a provider not belonging to this \(ValueCoordinator.self)"
                assertionFailure(msg)
                return
            }

            let lastActiveProviderIndex = providers.lastIndex(where: { $0.isActive })
            guard let lastActiveProviderIndex else {
                // There is no active provider
                throw ValueCoordinatorError.noActive
            }
            guard index == lastActiveProviderIndex else {
                // The update should be skipped cause the provider isn't the topmost active one
                throw ValueCoordinatorError.noTopmost
            }
        })) != nil else {
            return
        }

        update()
    }

    private func update() {
        onUpdate?(value)
    }
    
    private var hasActiveProviders: Bool {
        lastActiveProvider != nil
    }
    
    private var lastActiveProvider: ValueProvider<Value>? {
        lock.lock()
        defer {
            lock.unlock()
        }
        return providers.last(where: { $0.isActive })
    }

    private enum ValueCoordinatorError: Error {
        case noActive
        case noTopmost
    }

}

extension NSLocking {

    fileprivate func locking(_ block: ()throws -> ())throws {
        lock()
        defer {
            unlock()
        }

        try block()
    }

}
