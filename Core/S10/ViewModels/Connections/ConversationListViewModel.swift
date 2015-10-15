//
//  ConversationListViewModel.swift
//  S10
//
//  Created by Tony Xiao on 10/14/15.
//  Copyright © 2015 S10. All rights reserved.
//

import Foundation
import LayerKit

public class ConversationListViewModel: NSObject {
    
    let meteor: MeteorService
    let currentUser: CurrentUser
    
    public init(meteor: MeteorService, currentUser: CurrentUser) {
        self.meteor = meteor
        self.currentUser = currentUser
    }
    
    public func recipientForConversation(conversation: LYRConversation) -> UserViewModel? {
        if let u = conversation.recipient(meteor.mainContext, currentUserId: currentUser.userId.value) {
            return UserViewModel(user: u)
        }
        return nil
    }
    
    public func conversationVM(conversation: LYRConversation) -> LayerConversationViewModel {
        return LayerConversationViewModel(meteor: meteor, currentUser: currentUser, conversation: conversation)
    }
    
}