//
//  MeteorTests.swift
//  S10
//
//  Created by Tony Xiao on 6/17/15.
//  Copyright (c) 2015 S10. All rights reserved.
//

import Foundation
import XCTest
import Nimble
import Core
import Meteor
import OHHTTPStubs
import SwiftyJSON
import RealmSwift

var env: Environment!

class IntegrationTests : XCTestCase {
    var meteor: MeteorService!
    var videoService: VideoService!
    var notificationToken: NotificationToken?

    let PHONE_NUMBER = "6172596512"
    let CONNECTION_PHONE_NUMBER = "6501001010"
    let bundle = NSBundle(forClass: IntegrationTests.self)

    override class func setUp() {
        super.setUp()
        env = Environment(provisioningProfile: nil)
        Realm.defaultPath = NSHomeDirectory().stringByAppendingPathComponent("test.realm")
        deleteRealmFilesAtPath(Realm.defaultPath)
        OHHTTPStubs.stubRequestsPassingTest({ request in
            let isAzure = request.URL!.host!.rangeOfString("s10tv.blob.core.windows.net") != nil
            return isAzure
            }, withStubResponse: { _ in
                let stubData = "Hello World!".dataUsingEncoding(NSUTF8StringEncoding)
                return OHHTTPStubsResponse(data: stubData!, statusCode:200, headers:nil)
        })
    }

    override func setUp() {
        println("setup")
        meteor = MeteorService(serverURL: NSURL("ws://s10-dev.herokuapp.com/websocket"))
        meteor.delegate = self
        meteor.startup()
        videoService = VideoService(meteorService: meteor)
    }

    override func tearDown() {
        println("teardown")
        super.tearDown()
        meteor.logout()
    }
    
    func getResource(filename: String) -> NSURL? {
        return bundle.URLForResource(filename.stringByDeletingPathExtension, withExtension: filename.pathExtension)
    }
    
    func whileAuthenticated(block: () -> (RACSignal)) {
        let expectation = expectationWithDescription("Test Finished")
        self.meteor.loginWithPhoneNumber(self.PHONE_NUMBER).then {
            return self.meteor.vet(self.meteor.userID!)
        }.then {
            return block()
        }.then {
            return self.meteor.clearUserData(self.meteor.userID!)
        }.subscribeErrorOrCompleted { _ in
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(30, handler: nil)
    }

    func testConnection() {
        expect { self.meteor.connected }.toEventually(beTrue(), timeout: 2)
    }

    func testLoginWithPhoneNumber() {
        var expectation = self.expectationWithDescription("Log in to meteor with phone number")

        let PHONE_NUMBER = "6172596512"
        meteor.loginWithPhoneNumber(PHONE_NUMBER).then {
            expect(self.meteor.userID).notTo(beNil())
            expect(self.meteor.user).to(beNil()) // At this point userData hasn't been sent down yet
            return self.meteor.clearUserData(self.meteor.userID!)
        }.subscribeError({ (error) -> Void in
            expect(error) == nil
        }, completed: { () -> Void in
            expectation.fulfill()
        })

        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testUploadAvatar() {
        let image = self.getResource("test-avatar.jpg")?.path.flatMap { UIImage(contentsOfFile: $0) }
        expect(image).notTo(beNil())
        whileAuthenticated {
            let subject = RACReplaySubject()
            let upload = PhotoUploadOperation(meteor: self.meteor, image: image!, taskType: .ProfilePic)
            upload.completionBlock = {
                switch upload.result! {
                case .Success:
                    subject.sendCompleted()
                case .Error(let error):
                    subject.sendError(error)
                    XCTFail("Failed to upload \(error)")
                case .Cancelled:
                    subject.sendError(nil)
                    XCTFail("Upload unexpectedly cancelled")
                }
            }
            upload.start()
            return subject
        }
        // TODO: Verify that we can actually see the photo, it's identical to one we uploaded
        // and that the corresponding avatarUrl in currentUser gets changed
    }
    
    func testUploadCoverPhoto() {
        let image = self.getResource("test-avatar.jpg")?.path.flatMap { UIImage(contentsOfFile: $0) }
        expect(image).notTo(beNil())
        whileAuthenticated {
            let subject = RACReplaySubject()
            let upload = PhotoUploadOperation(meteor: self.meteor, image: image!, taskType: .CoverPic)
            upload.completionBlock = {
                switch upload.result! {
                case .Success:
                    subject.sendCompleted()
                case .Error(let error):
                    subject.sendError(error)
                    XCTFail("Failed to upload \(error)")
                case .Cancelled:
                    subject.sendError(nil)
                    XCTFail("Upload unexpectedly cancelled")
                }
            }
            upload.start()
            return subject
        }
    }

    func testSendVideo() {
        var userId: String?
        var otherUserId: String?

        var expectation = self.expectationWithDescription("Log in to meteor with phone number")

        let signal = self.meteor.loginWithPhoneNumber(self.PHONE_NUMBER).then {
            userId = self.meteor.userID
            return self.meteor.vet(userId!)
        }.then {
            return self.meteor.connectWithNewUser()
        }.flattenMap { res in
            let filePath = NSHomeDirectory().stringByAppendingPathComponent("test.txt")
            expect("hello world".writeToFile(
                filePath, atomically: true, encoding: NSUTF8StringEncoding, error: nil)) == true
            let url = NSURL(string: filePath)

            let connection = Connection.findByDocumentID(
                self.meteor.mainContext, documentID: res as! String)
            otherUserId = connection?.otherUser?.documentID

            self.videoService.sendVideoMessage(connection!.otherUser!, localVideoURL: url!)
            return RACSignal.empty()
        }

        var expectedNotifications = 2
        notificationToken = Realm().addNotificationBlock { notification, realm in
            if (expectedNotifications == 1) {

                // clear the DB to restore it.
                self.meteor.clearUserData(otherUserId!).then {
                    return self.meteor.clearUserData(userId!)
                }.subscribeCompleted {
                    expectation.fulfill()
                }
            } else {
                expectedNotifications--
            }
        }

        signal.subscribeError { (error) -> Void in
            expect(error).to(beNil())
        }

        self.waitForExpectationsWithTimeout(30.0, handler: nil)
    }

    class func deleteRealmFilesAtPath(path: String) {
        let fileManager = NSFileManager.defaultManager()
        fileManager.removeItemAtPath(path, error: nil)
        let lockPath = path + ".lock"
        fileManager.removeItemAtPath(lockPath, error: nil)
    }
}

// MARK: Meteor Logging
extension IntegrationTests : METDDPClientDelegate {
    func client(client: METDDPClient, willSendDDPMessage message: [NSObject : AnyObject]) {
        Log.verbose("DDP > \(message)")
    }
    func client(client: METDDPClient, didReceiveDDPMessage message: [NSObject : AnyObject]) {
        Log.verbose("DDP < \(message)")
    }
}