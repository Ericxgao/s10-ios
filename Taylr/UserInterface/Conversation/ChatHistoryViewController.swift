//
//  ChatHistoryViewController.swift
//  S10
//
//  Created by Tony Xiao on 10/14/15.
//  Copyright © 2015 S10. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Atlas
import Core

protocol ConversationHistoryDelegate: class {
    func didTapOnCameraButton()
}

class ChatHistoryViewController : ATLConversationViewController {
    
    weak var historyDelegate: ConversationHistoryDelegate?
    
    var vm: ConversationViewModel! {
        didSet { conversation = vm.conversation }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clearColor()
        messageInputToolbar.textInputView.font = UIFont(.cabinRegular, size: 17)
        dataSource = vm
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // #temp hack till we figure out better way
        collectionView.contentInset.top = 64
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // NOTE: Fix for messageInputToolbar not appearing sometimes if switching between chatHistory
        // and videoMaker too fast
        view.resignFirstResponder() // HACKIER FIX for when message does not show up
        view.becomeFirstResponder()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        vm.markAllNonVideoMessagesAsRead()
    }
    
    // override (superclass implement this, but not visible to subclass because)
    // it's not declared in the header file
    func messageInputToolbar(messageInputToolbar: ATLMessageInputToolbar!, didTapLeftAccessoryButton leftAccessoryButton: UIButton!) {
        historyDelegate?.didTapOnCameraButton()
    }
}

// MARK: - ATLConversationViewControllerDataSource

extension Participant : ATLParticipant {
    public var fullName: String! { return displayName }
    public var participantIdentifier: String! { return userId }
    public var avatarImageURL: NSURL! { return avatarURL }
    public var avatarImage: UIImage! { return nil }
    public var avatarInitials: String! { return nil }
}

extension ConversationViewModel : ATLConversationViewControllerDataSource {
    
    public func conversationViewController(conversationViewController: ATLConversationViewController!, participantForIdentifier participantIdentifier: String!) -> ATLParticipant! {
        return getParticipant(participantIdentifier)
    }
    
    public func conversationViewController(conversationViewController: ATLConversationViewController!, attributedStringForDisplayOfDate date: NSDate!) -> NSAttributedString! {
        return Formatters.attributedStringForDate(date)
    }
    
    public func conversationViewController(conversationViewController: ATLConversationViewController!, attributedStringForDisplayOfRecipientStatus recipientStatus: [NSObject : AnyObject]!) -> NSAttributedString! {
        return Formatters.attributedStringForDisplayOfRecipientStatus(recipientStatus, ctx: MainContext)
    }
    
}

extension ConversationViewModel : ATLConversationViewControllerDelegate {
    public func conversationViewController(conversationViewController: ATLConversationViewController!, configureCell cell: UICollectionViewCell!, forMessage message: LYRMessage!) {
        
    }
}