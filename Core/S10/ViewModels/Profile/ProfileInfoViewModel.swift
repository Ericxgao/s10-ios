//
//  ProfileInfoViewModel.swift
//  S10
//
//  Created by Tony Xiao on 7/25/15.
//  Copyright (c) 2015 S10. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Bond

public protocol ProfileInfoViewModel {
}

public struct TaylrProfileInfoViewModel : ProfileInfoViewModel{
    public let tagline: PropertyOf<String>
    public let about: PropertyOf<String>
    
    init(user: User) {
        tagline = user.pTagline()
        about = user.pAbout()
    }
}

public struct ConnectedProfileInfoViewModel : ProfileInfoViewModel {
    public struct Attribute {
        public let label: String
        public let value: String
    }
    
    public let avatar: Image
    public let displayName: String
    public let displayId: String
    public let authenticatedIcon: UIImage?
    public let themeColor: UIColor
    public let url: NSURL
    public let attributes: DynamicArray<Attribute>
    
    init(profile: User.ConnectedProfile) {
        avatar = profile.avatar
        displayName = profile.displayName
        displayId = profile.displayId ?? ""
        themeColor = profile.themeColor
        authenticatedIcon = profile.authenticated == true
            ? UIImage(named: "ic-approved")!.imageWithRenderingMode(.AlwaysTemplate) : nil
        url = profile.url
        attributes = DynamicArray(profile.attributes.map {
            Attribute(label: $0.label, value: $0.value)
        })
    }
}