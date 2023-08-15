//
//  ValueCoordinator
//
//  Created by Max Sol on 05/06/2022.
//

import XCTest
import ValueCoordinator

private var valueFromUpdate = ""
private var updateCount = 0

class ValueCoordinatorTests: XCTestCase {

    // Some demo implementations just for test purpose
    private class MergingValueCoordinator: ValueCoordinator<String>  {
        
        override var value: String {
            get {
                providers.reduce(rootValue) { $1.isActive ? $0 + $1.value : $0 }
            }
            
            set { super.value = newValue }
        }
        
    }

    private class MaximizingValueCoordinator: ValueCoordinator<Int>  {
        
        override var value: Int {
            get {
                providers.reduce(rootValue) { $1.isActive ? max($0, $1.value) : $0 }
            }
            
            set { super.value = newValue }
        }
        
    }

    // Current version of compiler crashes when property wrappers with custom initializers are declared inside methods,
    // so we use class properties
    @Coordinated(onUpdate: {
        valueFromUpdate = $0
    }) private var coordinated = "INITIAL"
    @Coordinated(coordinator: MergingValueCoordinator(rootValue: "a")) private var merging
    @Coordinated(coordinator: MaximizingValueCoordinator(rootValue: 5)) private var maximizing

    func testBasic() throws {
        XCTAssertEqual(coordinated, "INITIAL")

        coordinated = "0" // stack: 0
        XCTAssertEqual(coordinated, "0")
        XCTAssertEqual(valueFromUpdate, "0")

        do {
            @ValueProviding var prov1 = "1" // not connected, so stack: 0
            XCTAssertEqual(coordinated, "0")
            $prov1 = $coordinated // stack: 0 1
            XCTAssertEqual(coordinated, "1")
            prov1 = "2" // stack: 0 2
            XCTAssertEqual(coordinated, "2")

            do {
                @ValueProviding var prov2 = "3"
                $prov2 = $coordinated // stack: 0 2 3
                XCTAssertEqual(coordinated, "3")
            }
            // stack: 0 2
            let prov3 = ValueProvider(value: "4")
            prov3.appendToValueCoordinator($coordinated) // stack: 0 2 4
            XCTAssertEqual(coordinated, "4")

            do {
                @ValueProviding(isActive: false) var prov4 = "5"
                $prov4 = $coordinated // not active, so stack: 0 2 4
                XCTAssertEqual(coordinated, "4")
                _prov4.isActive = true // stack: 0 2 4 5
                XCTAssertEqual(coordinated, "5")
                
                _prov4.isActive = false // stack: 0 2 4
                XCTAssertEqual(coordinated, "4")
            }
            // stack: 0 2 4
            XCTAssertEqual(coordinated, "4")
            prov1 = "6" // stack: 0 6 4
            XCTAssertEqual(coordinated, "4")
            
            prov3.removeFromValueCoordinator() // stack: 0 6
            XCTAssertEqual(coordinated, "6")
        }
        // stack: 0
        XCTAssertEqual(coordinated, "0")
    }

    func testUpdate() {
        @Coordinated(onUpdate: { _ in
            updateCount += 1
        }) var coordinated = "a"
        coordinated = "b"
        XCTAssertEqual(updateCount, 1)
        coordinated = "c"
        XCTAssertEqual(updateCount, 2)
        
        let firstProvider = ValueProvider(value: "d")
        firstProvider.appendToValueCoordinator($coordinated)
        XCTAssertEqual(updateCount, 3)
        firstProvider.requestUpdateFromCoordinator()
        XCTAssertEqual(updateCount, 4)
        
        let secondProvider = ValueProvider(value: "e")
        secondProvider.appendToValueCoordinator($coordinated)
        XCTAssertEqual(updateCount, 5)
        
        // Update below should be skipped cause the provider isn't the topmost active one
        firstProvider.requestUpdateFromCoordinator()
        XCTAssertEqual(updateCount, 5)
    }
    
    func testConcurrent() {
        @Coordinated(onUpdate: { value in
            print(value)
        }) var coordinated = "INITIAL"

        DispatchQueue.global(qos: .background).async {
            let prov = ValueProvider(value: "")
            for i in 0..<100 {
                prov.value = "background \(i)"
                prov.appendToValueCoordinator($coordinated)
                prov.removeFromValueCoordinator()
            }
        }

        for defaultQueueIndex in 0...3 {
            DispatchQueue.global(qos: .default).async {
                let prov = ValueProvider(value: "")
                for i in 0..<100 {
                    prov.value = "default \(defaultQueueIndex) \(i)"
                    prov.appendToValueCoordinator($coordinated)
                    prov.removeFromValueCoordinator()
                }
            }
        }

        let expected = expectation(description: "callback happened")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expected.fulfill()
        }
        wait(for: [expected], timeout: 2)
    }

    func testMergingCoordinator() {
        XCTAssertEqual(merging, "a")

        do {
            @ValueProviding var b = "b"
            $b = $merging
            XCTAssertEqual(merging, "ab")

            @ValueProviding var c = "c"
            $c = $merging
            XCTAssertEqual(merging, "abc")
        }

        XCTAssertEqual(merging, "a")
    }

    func testMaximizingCoordinator() {
        XCTAssertEqual(maximizing, 5)

        do {
            @ValueProviding var b = 1
            $b = $maximizing
            XCTAssertEqual(maximizing, 5)

            @ValueProviding var c = 10
            $c = $maximizing
            XCTAssertEqual(maximizing, 10)
        }

        XCTAssertEqual(maximizing, 5)
    }

}
