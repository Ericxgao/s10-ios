//
//  ChatHistoryViewController.swift
//  S10
//
//  Created by Tony Xiao on 10/9/15.
//  Copyright © 2015 S10. All rights reserved.
//

import UIKit
import ReactiveCocoa
import SCRecorder
import Async
import Core

class ChatHistoryViewController : UIViewController {
    
    // TODO: Consider using AVQueuePlayer instead of SCPlayer for
    // gapless video playback
    @IBOutlet weak var playbackContainer: UIView!
    @IBOutlet weak var playerView: SCVideoPlayerView!
    @IBOutlet weak var durationTimer: DurationTimer!
    @IBOutlet weak var overlay: UIView!
    @IBOutlet weak var volumeView: VolumeView!
    @IBOutlet weak var timelineView: UICollectionView!
    
    var vm: ChatHistoryViewModel!
    var player: SCPlayer { return playerView.player! }
    var audioDisposable: Disposable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playerView.playerLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        player.delegate = self
        player.dyn("rate").producer.startWithNext { [weak self] _ in
            self?.vm.updateIsPlaying(self?.player.isPlaying ?? false)
        }
        
        playbackContainer.rac_hidden <~ vm.hidePlaybackViews
        overlay.rac_hidden <~ vm.isPlaying
        durationTimer.label.rac_text <~ vm.durationLeft
        vm.currentVideo.producer.startWithNext { [weak self] video in
            let videoURL = video?.url
            // NOTE: Despite the fact that we are on main thread it appears that
            // because MutableProperty dispatch_sync to a different queue
            // AVPlayer.setItemByUrl ends up being a no-op. I can't explain it but
            // dispatching it again to main thread works around this issue.
            // the temp variable video is needed to avoid compiler crash
            Async.main { [weak self] in
                self?.player.setItemByUrl(videoURL)
                //                Log.debug("set videoURL to \(videoURL)")
            }
        }
        timelineView <~ (vm.messages, TimelineCell.self)
        
        vm.currentVideoProgress.producer.startWithNext { [weak self] v in
            self?.durationTimer.progress = v
        }
        
        // Slight hack to get around the issue that playback momentarily stops when switching video
        vm.isPlaying.producer.startWithNext { [weak self] in
            let isPlaying = $0
            UIView.animate(0.25, options: [], delay: 0.25, animations: { [weak self] in
                self?.overlay.alpha = isPlaying ? 0 : 1
            })
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        player.beginSendingPlayMessages()
        // Whenever user presses volume button we'll switch to an active audio category
        // so that there's sound
        audioDisposable = AudioController.sharedController.systemVolume.producer
            .skip(1)
            .startWithNext { _ in
                AudioController.sharedController.setAudioCategory(.PlaybackAndRecord)
            }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        player.endSendingPlayMessages()
        vm.finishPlayback()
        audioDisposable?.dispose()
    }
    
    // MARK: -
    
    @IBAction func rewind() {
        if (player.currentTime().seconds < 2
            || player.itemDuration.seconds < 2
            || vm.currentVideo.value == nil)
            && vm.prevVideo() != nil {
            vm.seekPrevVideo()
        } else {
            player.seekToTime(CMTimeMakeWithSeconds(0, 1))
            player.play()
        }
    }
    
    @IBAction func playOrPause() {
        player.isPlaying ? player.pause() : player.play()
    }
    
    @IBAction func advance() {
        vm.seekNextVideo()
        Async.main { self.player.play() }
    }
}

extension ChatHistoryViewController : SCPlayerDelegate {
    
    func player(player: SCPlayer, didPlay currentTime: CMTime, loopsCount: Int) {
        if !player.itemDuration.impliedValue && !currentTime.impliedValue {
            vm.updatePlaybackPosition(currentTime.seconds)
        }
    }
    
    func player(player: SCPlayer, didReachEndForItem item: AVPlayerItem) {
        vm.finishPlayback()
    }
    
}

extension ChatHistoryViewController : UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        vm.seekVideoAtIndex(indexPath.item)
        Analytics.track("Message: Replay", ["MessageId": vm.currentVideo.value?.messageId ?? ""])
        Async.main { self.player.play() }
    }
}