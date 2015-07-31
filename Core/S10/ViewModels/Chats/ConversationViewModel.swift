//
//  ConversationViewModel.swift
//  S10
//
//  Created by Tony Xiao on 7/25/15.
//  Copyright (c) 2015 S10. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Bond
import RealmSwift

func messageLoader(sender: User?) -> () -> [MessageViewModel] {
    return {
        // TODO: Move this off the main thread
        assert(NSThread.isMainThread(), "Must be performed on main for now")
        let query = sender.map {
            Message.by(MessageKeys.sender.rawValue, value: $0)
            } ?? Message.all()
        
        let messages = query
            // MASSIVE HACK ALERT: Ascending should be true but empirically
            // ascending = false seems to actually give us the correct result. FML.
            .sorted(by: MessageKeys.createdAt.rawValue, ascending: false)
            .fetch().map { $0 as! Message }
        
        var playableMessages: [MessageViewModel] = []
        for message in messages {
            if let localURL = VideoCache.sharedInstance.getVideo(message.documentID!) {
                playableMessages.append(MessageViewModel(message: message, localVideoURL: localURL))
            }
        }
        return playableMessages
    }
}

// Class or struct?
public class ConversationViewModel {
    public enum Page : Int {
        case Player = 0
        case Producer = 1
    }
    public enum State {
        case PlaybackStopped
        case PlaybackPlaying
        case RecordIdle
        case RecordCapturing
    }

    let meteor: MeteorService
    let taskService: TaskService
    let _messages: MutableProperty<[MessageViewModel]>
    let recipient: User?
    let currentUser: PropertyOf<User?>
    let currentMessageDate: PropertyOf<String?>
    let currentConversationStatus: PropertyOf<String?>
    var openedMessages = Set<Message>()
    
    public let playing: MutableProperty<Bool>
    public let recording: MutableProperty<Bool>
    public let page: MutableProperty<Page>
    
    public let state: PropertyOf<State>
    public let avatar: PropertyOf<Image?>
    public let firstName: PropertyOf<String>
    public let displayName: PropertyOf<String>
    public let displayStatus: PropertyOf<String>
    public let busy: PropertyOf<Bool>
    public let messages: PropertyOf<[MessageViewModel]>
    public let hideSwipeUpHint: PropertyOf<Bool>
    public let hideSwipeDownHint: PropertyOf<Bool>
    public let exitAtEnd: Bool
    
    public let currentMessage: MutableProperty<MessageViewModel?>
  
    init(meteor: MeteorService, taskService: TaskService, recipient: User?) {
        self.meteor = meteor
        self.taskService = taskService
        self.recipient = recipient
        let loadMessages = messageLoader(recipient)
        
        _messages = MutableProperty(loadMessages())
        messages = PropertyOf(_messages)
        playing = MutableProperty(false)
        recording = MutableProperty(false)
        page = MutableProperty(_messages.value.count > 0 ? .Player : .Producer)
        state = PropertyOf(.PlaybackStopped, combineLatest(
            page.producer,
            playing.producer,
            recording.producer
        ) |> map {
            switch $0 {
            case .Player: return $1 ? .PlaybackPlaying : .PlaybackStopped
            case .Producer: return $2 ? .RecordCapturing : .RecordIdle
            }
        })

        exitAtEnd = recipient == nil
        currentMessage = MutableProperty(nil)
        currentUser = currentMessage
            |> map { $0?.message.sender ?? recipient }
        avatar = currentUser
            |> flatMap { $0.pAvatar() }
        firstName = currentUser
            |> flatMap(nilValue: "") { $0.pFirstName() }
        displayName = currentUser
            |> flatMap(nilValue: "") { $0.pDisplayName() }
        busy = currentUser
            |> flatMap(nilValue: false) { $0.pConversationBusy() }
        hideSwipeUpHint = state
            |> map { $0 != .PlaybackStopped }
         // TODO: Should also depend on whether or not there's actually new messages
        hideSwipeDownHint = state
            |> map { $0 != .RecordIdle }
        
        currentMessageDate = currentMessage
            |> flatMap { $0.formattedDate |> map { Optional($0) } }
        currentConversationStatus = currentUser
            |> flatMap { $0.pConversationStatus() |> map { Optional($0) } }
        displayStatus = PropertyOf("", combineLatest(
            state.producer,
            currentMessageDate.producer,
            currentConversationStatus.producer
        ) |> map {
            switch $0 {
            case .PlaybackStopped, .PlaybackPlaying:
                return $1 ?? $2 ?? ""
            case .RecordIdle, .RecordCapturing:
                return $2 ?? ""
            }
        })
        
        // NOTE: ManagedObjectContext changes are ignored
        // So if video is removed nothing will happen
        _messages <~ Realm().notifier() |> map { _ in loadMessages() } |> skipRepeats { $0 == $1 }
    }
    
    public func openMessage(message: MessageViewModel) {
        openedMessages.insert(message.message)
    }
    
    public func expireOpenedMessages() {
        for message in openedMessages {
            VideoCache.sharedInstance.removeVideo(message.documentID!)
        }
        meteor.expireMessages(Array(openedMessages))
        openedMessages.removeAll()
    }
    
    public func sendVideo(localURL: NSURL) {
        if let user = currentUser.value {
            taskService.uploadVideo(user, localVideoURL: localURL)
        }
    }
    
    public func reportUser(reason: String) {
        currentUser.value.map { meteor.reportUser($0, reason: reason) }
    }
    
    public func blockUser() {
        currentUser.value.map { meteor.blockUser($0) }
    }
    
    public func profileVM() -> ProfileViewModel {
        return ProfileViewModel(meteor: meteor, taskService: taskService, user: currentUser.value!)
    }
}