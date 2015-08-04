//
//  PlayerViewModel.swift
//  S10
//
//  Created by Tony Xiao on 7/20/15.
//  Copyright (c) 2015 S10. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Core

protocol PlayableVideo {
    var uniqueId: String { get }
    var url: NSURL { get }
    var duration: NSTimeInterval { get }
}

protocol PlayerDelegate : class {
    func playerDidFinishPlaylist(player: PlayerViewModel)
    func player(player: PlayerViewModel, willPlayVideo video: PlayableVideo)
    func player(player: PlayerViewModel, didPlayVideo video: PlayableVideo)
}

private func findVideo(video: PlayableVideo?, inPlaylist playlist: [PlayableVideo]) -> Int? {
    for (index, v) in enumerate(playlist) {
        if v.uniqueId == video?.uniqueId {
            return index
        }
    }
    return nil
}

// TODO: Struct vs. class?
// For some reason struct causes crash, also doesn't work quite well with the idea of
// delegate. Need to figure out a better pattern of whether struct or class is the right
// approach and when
// http://www.objc.io/issues/16-swift/swift-classes-vs-structs/#the-advantages-of-value-types
class PlayerViewModel {
    private let currentVideo = MutableProperty<PlayableVideo?>(nil)
    private let currentTime = MutableProperty<NSTimeInterval>(0)
    private let _isPlaying = MutableProperty(false)
    private let unfinishedVideoDuration: PropertyOf<NSTimeInterval>
    weak var delegate: PlayerDelegate?
    
    let playlist = MutableProperty<[PlayableVideo]>([])
    let videoURL: PropertyOf<NSURL?>
    let isPlaying: PropertyOf<Bool>
    let currentVideoProgress: PropertyOf<Float>
    let totalDurationLeft: PropertyOf<String>
    let hideView: PropertyOf<Bool>
    var finishedAtIndex: Int?
    
    init() {
        videoURL = currentVideo |> map { $0?.url }
        isPlaying = PropertyOf(_isPlaying)
        unfinishedVideoDuration = PropertyOf(0, combineLatest(
            currentVideo.producer,
            playlist.producer
        ) |> map {currentVideo, playlist in
            let i = findVideo(currentVideo, inPlaylist: playlist) ?? 0
            return playlist[i..<playlist.count]
                .map { $0.duration }
                .reduce(0, combine: +)
        })
        currentVideoProgress = PropertyOf(0, combineLatest(
            currentVideo.producer,
            currentTime.producer
        ) |> map { video, time in
            video.map { Float(time / $0.duration) } ?? 0
        })
        totalDurationLeft = PropertyOf("", combineLatest(
            currentTime.producer,
            unfinishedVideoDuration.producer
        ) |> map { currentTime, unfinishedVideoDuration in
            let secondsLeft = Int(ceil(max(unfinishedVideoDuration - currentTime, 0)))
            return "\(secondsLeft)"
        })
        hideView = currentVideo |> map { $0 == nil }
        // If we are at the end and new video arrives we'll automatically try to play it
        playlist.producer.start(next: { [weak self] playlist in
            if let this = self,
            let index = this.finishedAtIndex where index < playlist.count - 1 {
                this.seekVideo(playlist[index + 1])
            }
        })
    }
    
    func prevVideo() -> PlayableVideo? {
        if currentVideo.value == nil {
            return playlist.value.last
        }
        return currentVideoIndex().flatMap {
            $0 > 0 ? $0 - 1 : nil
        }.map { playlist.value[$0] }
    }
    
    func nextVideo() -> PlayableVideo? {
        if currentVideo.value == nil {
            return playlist.value.first
        }
        return currentVideoIndex().flatMap {
            $0 < playlist.value.count - 1 ? $0 + 1 : nil
        }.map { playlist.value[$0] }
    }
    
    func seekPrevVideo() -> Bool {
        return seekVideo(prevVideo())
    }
    
    func seekNextVideo() -> Bool {
        let played = seekVideo(nextVideo())
        if !played {
            finishedAtIndex = playlist.value.count - 1
            delegate?.playerDidFinishPlaylist(self)
        }
        return played
    }
    
    // MARK: - Hooks for PlayerViewController to update state
    
    func updatePlaybackPosition(position: NSTimeInterval) {
        currentTime.value = position
    }
    
    func updateIsPlaying(isPlaying: Bool) {
        _isPlaying.value = isPlaying
    }
    
    // MARK: - 
    
    private func seekVideo(video: PlayableVideo?) -> Bool {
        Log.debug("Will seek video with id \(video?.uniqueId) url: \(video?.url)")
        finishedAtIndex = nil
        currentVideo.value.map { delegate?.player(self, didPlayVideo: $0) }
        currentTime.value = 0
        currentVideo.value = video
        video.map { delegate?.player(self, willPlayVideo: $0) }
        return video != nil
    }
    
    private func currentVideoIndex() -> Int? {
        return findVideo(currentVideo.value, inPlaylist: playlist.value)
    }
}
