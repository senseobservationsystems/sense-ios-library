//
//  DataSyncerTest.swift
//  SensePlatform
//
//  Created by Fei on 22/10/15.
//
//

import XCTest
@testable import DSESwift
import PromiseKit


enum PromiseTestError: ErrorType{
    case Number1
    case Number2
}

class PromiseTests: XCTestCase{

    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func sleep(duration: Double) {
        let date = NSDate();
        repeat {} while(NSDate().timeIntervalSince1970 - date.timeIntervalSince1970 < duration)
    }
    
    func promiseSleep(duration: Double, _ message:String = "") -> Promise<Void> {
        print(message)
        return Promise<Void> { fulfill, reject in
            self.sleep(duration);
            fulfill()
        }
    }
    
    func promiseNightmare(duration: Double, _ throwError: Int) throws -> Promise<Void> {
        return Promise<Void> { fulfill, reject in
            self.sleep(duration);
            if (throwError == 1) {
                throw PromiseTestError.Number1
            }
            else {
                throw PromiseTestError.Number2
            }
            fulfill()
        }
    }
    
    
    func promiseSleepReturningBool(duration: Double, _ message:Bool = false) -> Promise<Bool> {
        print(message)
        return Promise<Bool> { fulfill, reject in
            self.sleep(duration);
            fulfill(true)
        }
    }
    
    func testPromisesFormats() {
        let response = self.expectationWithDescription("wait for promises")
        
        let a = Promise<Void> {fulfill, reject in
            sleep(0.1)
            fulfill()
        }
        a.then{
            print("im after promise a")
        }
    
        
        firstly ({
            return self.promiseSleep(0.1, "setting up promiseSleep with Firstly () ")
        }).then ({
            return self.promiseSleep(0.1, "after Firstly () 1")
        }).then ({
            return self.promiseSleep(0.1, "after Firstly () 2")
        })
        
        firstly ({
            return self.promiseSleepReturningBool(0.1, false)
        }).then ({ value in
            return self.promiseSleepReturningBool(0.1, value)
        }).then ({ value in
            return self.promiseSleepReturningBool(0.1, value)
        }).then({ _ in
            response.fulfill()
        })
        
        print("end of test, waiting for async")
        //wait for asynchronous call to complete before running assertions
        self.waitForExpectationsWithTimeout(2.0) { _ -> Void in
            print("timeout");
        }
    }
    
    func testPromisesOnThreads() {
        let response = self.expectationWithDescription("wait for promises")
        
        // the concurrent queue also performs consecutively since we schedule the next task only once the previous one is completed
        //let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        // consecutive queue
        let queue = dispatch_queue_create("hello World", nil);
        
        dispatch_promise(on: queue, body: { _ -> Promise<Void> in
            print ("because of this print I have to define a return type")
            return self.promiseSleep(0.2)
        }).then(on: queue, { _ in
            return self.promiseSleep(0.2)
        })
        .then(on: dispatch_get_main_queue(), {
            response.fulfill()
        })

        self.waitForExpectationsWithTimeout(3.0) { _ -> Void in
            print("timeout");
        }
    }
    
    func testPromisesWithErrorHandling() {
        let response = self.expectationWithDescription("wait for promises")
        
        firstly ({ _ -> Promise<Void> in
            print("1")
            return try self.promiseNightmare(0.1, 2)
        })
        .then ({ _ -> Promise<Void> in
            print("2")
            return self.promiseSleep(0.1)
        }).then ({ _ -> Promise<Void> in
            print("3")
            return try self.promiseNightmare(0.1, 1)
        }).then({ _ in
            print("4")
        }).always({
            print("I always get here regardless of Errors")
        }).error({error in
            print(error)
        })
        
        firstly ({ _ -> Promise<Void> in
            print("1")
            return try self.promiseNightmare(0.1, 2)
        }).recover({Error in
            print("error: \(Error)")
        })
        .then ({ _ -> Promise<Void> in
            print("2")
            return self.promiseSleep(0.1)
        }).then ({ _ -> Promise<Void> in
            print("3")
            return try self.promiseNightmare(0.1, 1)
        }).then({ _ in
            print("4")
        }).error({(error: ErrorType) -> Void in
            print("in the error handler: \(error)")
            response.fulfill()
        })
        
        print("end of test, waiting for async")
        //wait for asynchronous call to complete before running assertions
        self.waitForExpectationsWithTimeout(2.0) { _ -> Void in
            print("timeout");
        }
    }
    
    func testPromisesWithErrorHandlingInThreads() {
        let response = self.expectationWithDescription("wait for promises")
        
        // the concurrent queue also performs consecutively since we schedule the next task only once the previous one is completed
        //let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        // consecutive queue
        let queue = dispatch_queue_create("hello World", nil);
        
        dispatch_promise(on: queue, body: { _ -> Promise<Void> in
            print ("because of this print I have to define a return type")
            return self.promiseSleep(0.2)
        }).then(on: queue, { _ in
            return self.promiseSleep(0.2)
        }).then(on: queue, { _ in
            return try self.promiseNightmare(0.2,2)
        }).then(on: queue, { _ in
            return self.promiseSleep(0.2)
        })
        .then(on: dispatch_get_main_queue(), {
            response.fulfill()
        }).error({(error: ErrorType) -> Void in
            print("in the error handler: \(error)")
            response.fulfill()
        })

        
        self.waitForExpectationsWithTimeout(3.0) { _ -> Void in
            print("timeout");
        }

    }
    
    
    
    
}

