//
//  InviteTask.swift
//  S10
//
//  Created by Tony Xiao on 7/25/15.
//  Copyright (c) 2015 S10. All rights reserved.
//

import Foundation
import ReactiveCocoa
import RealmSwift

// TODO: Do not store absolute path to local files in the database because they contain
// uuid of the sandbox which might sometimes change after application upgrade
internal class InviteTask : Object {
    dynamic var taskId = ""
    dynamic var localVideoUrl = ""
    dynamic var firstName = ""
    dynamic var lastName = ""
    dynamic var thumbnailData = NSData()
    dynamic var videoWidth = 0
    dynamic var videoHeight = 0
    dynamic var emailOrPhone = ""
    
    override static func primaryKey() -> String? {
        return "taskId"
    }
    
    class func findByTaskId(taskId: String, realm: Realm = unsafeNewRealm()) -> InviteTask? {
        let pred = NSPredicate(format: "taskId = %@", taskId)
        return realm.objects(self).filter(pred).first
    }
    
    class func countInvites(realm: Realm = unsafeNewRealm()) -> Int {
        return realm.objects(self).count
    }
    
    class func countOfInvites() -> SignalProducer<Int, NoError> {
        return unsafeNewRealm().notifier().map { _ in self.countInvites() }
    }
}