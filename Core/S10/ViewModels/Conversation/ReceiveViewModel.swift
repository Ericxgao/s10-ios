//
//  ReceiveViewModel.swift
//  S10
//
//  Created by Tony Xiao on 10/8/15.
//  Copyright © 2015 S10. All rights reserved.
//

import Foundation
import LayerKit
import ReactiveCocoa

public class ReceiveViewModel {
    private let ctx: Context
    
    public let playlist: ArrayProperty<VideoMessageViewModel>
    public let totalDurationLeft: PropertyOf<String>
    public let currentVideo: PropertyOf<VideoMessageViewModel?>
    public let currentVideoProgress: PropertyOf<Float>
    public let currentVideoPosition = MutableProperty<NSTimeInterval>(0)
    public let isPlaying = MutableProperty(false)
    
    init(_ ctx: Context, conversation: LYRConversation) {
        self.ctx = ctx
        let videos = ctx.layer.unplayedVideoMessages(conversation).map { msg -> VideoMessageViewModel in
            let parts = msg.parts.map { $0 as! LYRMessagePart }
            return VideoMessageViewModel(identifier: msg.identifier.absoluteString, url: parts.first!.fileURL, duration: 5)
        }
        playlist = ArrayProperty(videos)
        currentVideo = PropertyOf(nil, playlist.producer.map { $0.first }
            .skipRepeats { $0?.identifier == $1?.identifier })
        currentVideoProgress = PropertyOf(0, combineLatest(
            currentVideo.producer,
            currentVideoPosition.producer
        ).map { video, time in
            video.map { Float(min(time / $0.duration, 1)) } ?? 0
        })
        totalDurationLeft = PropertyOf("", combineLatest(
            currentVideoPosition.producer,
            playlist.producer
        ).map { position, playlist in
            let total = playlist.map { $0.duration }.reduce(0, combine: +)
            let secondsLeft = Int(ceil(max(total - position, 0)))
            return "\(secondsLeft)"
        })
    }
    
    public func seekNextVideo() -> Bool {
        if let _ = playlist.dequeue() {
//            meteor.openMessage(video.message)
        }
        return currentVideo.value != nil
    }
}

