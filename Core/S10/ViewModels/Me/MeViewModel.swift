//
//  MeViewModel.swift
//  S10
//
//  Created by Tony Xiao on 6/30/15.
//  Copyright (c) 2015 S10. All rights reserved.
//

import Foundation
import Meteor
import ReactiveCocoa

public struct MeViewModel {
    let meteor: MeteorService
    let taskService: TaskService
    public let subscription: MeteorSubscription
    public let avatar: PropertyOf<Image?>
    public let cover: PropertyOf<Image?>
    public let displayName: PropertyOf<String>
    public let profileIcons: ArrayProperty<Image>
    public let hashtags: ArrayProperty<HashtagViewModel>
    
    public init(meteor: MeteorService, taskService: TaskService) {
        self.meteor = meteor
        self.taskService = taskService
        subscription = meteor.subscribe("me")
        avatar = meteor.user.flatMap { $0.pAvatar() }
        cover = meteor.user.flatMap { $0.pCover() }
        displayName = meteor.user.flatMap(nilValue: "") { $0.pDisplayName() }
        profileIcons = meteor.user
            .flatMap(nilValue: []) { $0.pConnectedProfiles() }
            .map { $0.map { $0.icon } }
            .array()
        hashtags = ArrayProperty([
            HashtagViewModel(text: "eco101", selected: true),
            HashtagViewModel(text: "taylrswift", selected: true),
            HashtagViewModel(text: "skiing", selected: true),
            HashtagViewModel(text: "snowboard", selected: true),
            HashtagViewModel(text: "manila", selected: true),
            HashtagViewModel(text: "surf", selected: true)
        ])
    }
    
    public func canViewOrEditProfile() -> Bool {
        return meteor.user.value != nil
    }
    
    public func profileVM() -> ProfileViewModel? {
        return meteor.user.value.map { ProfileViewModel(meteor: meteor, taskService: taskService, user: $0) }
    }
    
    public func editProfileVM() -> EditProfileViewModel? {
        return meteor.user.value.map { EditProfileViewModel(meteor: meteor, user: $0) }
    }
}