//
//  ConversationViewController.swift
//  Taylr
//
//  Created by Tony Xiao on 6/14/15.
//  Copyright (c) 2015 Taylr. All rights reserved.
//

import Foundation
import ReactiveCocoa
import PKHUD
import Bond
import Async
import SwipeView
import Core

class ConversationViewController : BaseViewController {
    
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var activityLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var swipeView: SwipeView!
    
    var player: PlayerViewController!
    var producer: ProducerViewController!
    var vm: ConversationViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let avkit = UIStoryboard(name: "AVKit", bundle: nil)
        player = avkit.instantiateViewControllerWithIdentifier("Player") as! PlayerViewController
        player.vm.delegate = self
        producer = avkit.instantiateViewControllerWithIdentifier("Producer") as! ProducerViewController
        producer.producerDelegate = self
        
        addChildViewController(player)
        addChildViewController(producer)
        swipeView.vertical = true
        swipeView.bounces = false
        swipeView.dataSource = self
        swipeView.delegate = self
        player.didMoveToParentViewController(self)
        player.didMoveToParentViewController(self)
        
        vm.reloadMessages()
        vm.avatar ->> avatarView.imageBond
        vm.displayName ->> nameLabel
        vm.busy ->> spinner
        vm.displayStatus ->> activityLabel
        
        player.vm.playlist <~ (vm.messages |> map { $0.map { (msg: MessageViewModel) in msg as PlayableVideo } })
        if player.vm.playNextVideo() {
            showPlayer()
        }
//        else {
//            showProducer()
//        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let scrollView = swipeView.valueForKey("scrollView") as! UIScrollView
        scrollView.contentInset = UIEdgeInsetsZero
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.setBackgroundColor(UIColor(white: 0.5, alpha: 0.4))
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.setBackgroundColor(nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationViewController as? ProfileViewController {
            vc.vm = vm.profileVM()
        }
    }
    
    // MARK: - Actions
    
    func showPlayer(animated: Bool = false) {
        swipeView.scrollToItemAtIndex(0, duration: animated ? 0.25 : 0)
    }
    
    func showProducer(animated: Bool = false) {
        swipeView.scrollToItemAtIndex(1, duration: animated ? 0.25 : 0)
    }
    
    @IBAction func showMoreOptions(sender: AnyObject) {
//        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
//        sheet.addAction(LS(.moreSheetBlock, conversationVM.recipient.firstName!), style: .Destructive) { _ in
//            self.blockUser(sender)
//        }
//        sheet.addAction(LS(.moreSheetReport, conversationVM.recipient.firstName!), style: .Destructive) { _ in
//            self.reportUser(sender)
//        }
//        sheet.addAction(LS(.moreSheetCancel), style: .Cancel)
//        presentViewController(sheet)
    }
    
    @IBAction func blockUser(sender: AnyObject) {
//        let alert = UIAlertController(title: LS(.reportAlertTitle), message: LS(.reportAlertMessage), preferredStyle: .Alert)
//        alert.addAction(LS(.reportAlertCancel), style: .Cancel)
//        alert.addAction(LS(.reportAlertConfirm), style: .Destructive) { _ in
//            Meteor.blockUser(self.conversationVM.recipient)
//        }
//        presentViewController(alert)
    }
    
    @IBAction func reportUser(sender: AnyObject) {
//        let alert = UIAlertController(title: LS(.reportAlertTitle), message: LS(.reportAlertMessage), preferredStyle: .Alert)
//        alert.addTextFieldWithConfigurationHandler(nil)
//        alert.addAction(LS(.reportAlertCancel), style: .Cancel)
//        alert.addAction(LS(.reportAlertConfirm), style: .Destructive) { _ in
//            if let reportReason = (alert.textFields?[0] as? UITextField)?.text {
//                Meteor.reportUser(self.conversationVM.recipient, reason: reportReason)
//            }
//        }
//        presentViewController(alert)
    }
}

extension ConversationViewController : SwipeViewDataSource {
    func numberOfItemsInSwipeView(swipeView: SwipeView!) -> Int {
        return 2
    }
    
    func swipeView(swipeView: SwipeView!, viewForItemAtIndex index: Int, reusingView view: UIView!) -> UIView! {
        return index == 0 ? player.view : producer.view
    }
}

extension ConversationViewController : SwipeViewDelegate {
    
    func swipeViewCurrentItemIndexDidChange(swipeView: SwipeView!) {
        
    }
}



extension ConversationViewController : ProducerDelegate {
    
    func producerWillStartRecording(producer: ProducerViewController) {
//        conversationVM.recording.value = true
    }
    
    func producerDidCancelRecording(producer: ProducerViewController) {
//        conversationVM.recording.value = false
    }
    
    func producer(producer: ProducerViewController, didProduceVideo url: NSURL) {
//        conversationVM.recording.value = false
        Log.info("I got a video \(url)")
//        Globals.taskService.uploadVideo(conversationVM.recipient, localVideoURL: url)
        PKHUD.hide(animated: false)
    }
}

extension ConversationViewController : PlayerDelegate {
    func playerDidFinishPlaylist(player: PlayerViewModel) {
        
    }
    
    func player(player: PlayerViewModel, willPlayVideo video: PlayableVideo) {
        
    }
    
    func player(player: PlayerViewModel, didPlayVideo video: PlayableVideo) {
        
    }
}

extension MessageViewModel : PlayableVideo {
    var uniqueId: String { return messageId }
    var url: NSURL { return localVideoURL }
    var duration: NSTimeInterval { return videoDuration }
}



//func player(player: , didFinishVideo video: PlayableVideo) {
//    if interactor.videoQueue.count == 0 {
//        showProducer(animated: true)
//    }
//    //        // TODO: Move into ViewModel
//    //        if let message = (video as? MessageViewModel)?.message
//    //            where message.fault == false // Hack for now to avoid EXC_BAD_INSTRUCTION
//    //                && message.sender != nil // Hack for now to avoid nil crash
//    //                && message.incoming && message.statusEnum != .Opened {
//    //            Meteor.openMessage(message, expireDelay: 0)
//    //            if let videoId = message.video?.documentID {
//    //                VideoCache.sharedInstance.removeVideo(videoId)
//    //            }
//    //        }
//}
