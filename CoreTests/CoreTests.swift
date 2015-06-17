//
//  CoreTests.swift
//  CoreTests
//
//  Created on 1/24/15.
//  Copyright (c) 2015 S10. All rights reserved.
//

import UIKit
import XCTest
import Core
import Nimble

class CoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }
    
    func testAgain() {
        XCTAssertTrue(true, "fail")
    }
    
    func testExpectSyntax() {
        let variable = 1222
        expect(variable) == 1222
    }
    
    func testArrayViewModel() {
        let task = Task(clientId: "", type: "")
        XCTAssertNotNil(task, "")
//        let vm = ArrayViewModel(content: ["1", "2", "3", "4"])
//        XCTAssertEqual(vm.numberOfItemsInSection(0), 4, "Should have 4 items")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
