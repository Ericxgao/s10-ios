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

extension MessageViewModel : PlayableVideo {
    var uniqueId: String { return messageId }
    var url: NSURL { return localVideoURL }
    var duration: NSTimeInterval { return videoDuration }
}

class ConversationViewController : BaseViewController {

    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var activityLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var swipeView: SwipeView!
    @IBOutlet weak var playerEmptyView: UIView!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var newMessagesHint: UIView!
    @IBOutlet var producerContainer: UIView!
    @IBOutlet var playerContainer: UIView!
    @IBOutlet var tutorialContainer: UIView!
    
    var player: PlayerViewController!
    var producer: ProducerViewController!
    var tutorial: ConversationTutorialViewController!
    var vm: ConversationViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        vm.avatar ->> avatarView.imageBond
        vm.displayName ->> nameLabel
        vm.busy ->> spinner
        vm.displayStatus ->> activityLabel
        vm.hideNewMessagesHint ->> newMessagesHint.dynHidden
        vm.cover ->> coverImageView.imageBond
        
        let avkit = UIStoryboard(name: "AVKit", bundle: nil)
        producer = avkit.instantiateViewControllerWithIdentifier("Producer") as! ProducerViewController
        producer.producerDelegate = self
        player = avkit.instantiateViewControllerWithIdentifier("Player") as! PlayerViewController
        player.vm.delegate = self
        player.vm.playlist <~ (vm.messages.producer |> map {
            $0.map { (msg: MessageViewModel) in msg as PlayableVideo }
        })
        vm.playing <~ player.vm.isPlaying
        
        addChildViewController(player)
        playerContainer.addSubview(player.view)
        player.view.makeEdgesEqualTo(playerContainer)
        player.didMoveToParentViewController(self)
        
        addChildViewController(producer)
        producerContainer.insertSubview(producer.view, atIndex: 0)
        producer.view.makeEdgesEqualTo(producerContainer)
        producer.didMoveToParentViewController(self)
        
        [playerContainer, producerContainer].each {
            $0.bounds = view.bounds
            $0.removeFromSuperview()
            $0.setTranslatesAutoresizingMaskIntoConstraints(true)
        }
    
        swipeView.vertical = true
        swipeView.bounces = false
        swipeView.currentItemIndex = 0//vm.page.value.rawValue
        swipeView.dataSource = self
        swipeView.delegate = self
        swipeView.layoutIfNeeded()
        
        if !vm.showTutorial {
            tutorialContainer.removeFromSuperview()
            player.advance()
        } else {
            playerEmptyView.hidden = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let scrollView = swipeView.valueForKey("scrollView") as! UIScrollView
        scrollView.contentInset = UIEdgeInsetsZero
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.setBackgroundColor(UIColor(white: 0.5, alpha: 0.4))
        navigationController?.lastViewController?.navigationItem.backBarButtonItem?.title = "Leave"
        if let view = navigationItem.titleView {
            view.bounds.size = view.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.setBackgroundColor(nil)
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)
        if parent == nil {
            vm.expireOpenedMessages()
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if identifier == SegueIdentifier.ConversationToProfile.rawValue
            && navigationController?.lastViewController is ProfileViewController {
                navigationController?.popViewControllerAnimated(true)
                return false
        }
        return super.shouldPerformSegueWithIdentifier(identifier, sender: sender)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationViewController as? ProfileViewController {
            vc.vm = vm.profileVM()
        }
        if let vc = segue.destinationViewController as? ConversationTutorialViewController {
            vc.delegate = self
        }
    }
    
    // MARK: Actions
    func showPage(page: ConversationViewModel.Page, animated: Bool = false) {
        swipeView.scrollToItemAtIndex(page.rawValue, duration: animated ? 0.25 : 0)
    }

    @IBAction func didTapLeave(sender: AnyObject) {
        vm.expireOpenedMessages()
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func showMoreOptions(sender: AnyObject) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        sheet.addAction(LS(.viewProfile)) { _ in
            self.performSegue(.ConversationToProfile)
        }
        sheet.addAction(LS(.moreSheetBlock, vm.firstName.value), style: .Destructive) { _ in
            self.blockUser(self)
        }
        sheet.addAction(LS(.moreSheetReport, vm.firstName.value), style: .Destructive) { _ in
            self.reportUser(self)
        }
        sheet.addAction(LS(.moreSheetCancel), style: .Cancel)
        presentViewController(sheet)
    }
    
    @IBAction func blockUser(sender: AnyObject) {
        let alert = UIAlertController(title: LS(.reportAlertTitle), message: LS(.reportAlertMessage), preferredStyle: .Alert)
        alert.addAction(LS(.reportAlertCancel), style: .Cancel)
        alert.addAction(LS(.reportAlertConfirm), style: .Destructive) { _ in
            self.vm.blockUser()
        }
        presentViewController(alert)
    }
    
    @IBAction func reportUser(sender: AnyObject) {
        let alert = UIAlertController(title: LS(.reportAlertTitle), message: LS(.reportAlertMessage), preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler(nil)
        alert.addAction(LS(.reportAlertCancel), style: .Cancel)
        alert.addAction(LS(.reportAlertConfirm), style: .Destructive) { _ in
            if let reportReason = (alert.textFields?[0] as? UITextField)?.text {
                self.vm.reportUser(reportReason)
            }
        }
        presentViewController(alert)
    }
}

// MARK: - Tutorial

extension ConversationViewController : ConversationTutorialDelegate {
    func tutorialDidFinish() {
        playerEmptyView.hidden = false
        tutorialContainer.removeFromSuperview()
        if player.vm.nextVideo() != nil {
            player.advance()
        }
    }
}

// MARK: - SwipeView Delegate & DataSource

extension ConversationViewController : SwipeViewDataSource {
    func numberOfItemsInSwipeView(swipeView: SwipeView!) -> Int {
        return 2
    }
    
    func swipeView(swipeView: SwipeView!, viewForItemAtIndex index: Int, reusingView view: UIView!) -> UIView! {
        return index == ConversationViewModel.Page.Player.rawValue ? playerContainer : producerContainer
    }
}

extension ConversationViewController : SwipeViewDelegate {
    func swipeViewCurrentItemIndexDidChange(swipeView: SwipeView!) {
        vm.page.value = ConversationViewModel.Page(rawValue: swipeView.currentItemIndex)!
    }
}

// MARK: - Producer Delegate

extension ConversationViewController : ProducerDelegate {
    func producerWillStartRecording(producer: ProducerViewController) {
        vm.recording.value = true
    }
    
    func producerDidCancelRecording(producer: ProducerViewController) {
        vm.recording.value = false
    }
    
    func producer(producer: ProducerViewController, didProduceVideo url: NSURL) {
        vm.recording.value = false
        Log.info("Will send video \(url)")
        vm.sendVideo(url)
        PKHUD.hide(animated: false)
    }
}

// MARK: - Player Delegate

extension ConversationViewController : PlayerDelegate {
    func playerDidFinishPlaylist(player: PlayerViewModel) {
        if vm.exitAtEnd {
            navigationController?.popViewControllerAnimated(true)
        } else {
            showPage(.Producer, animated: true)
        }
    }
    
    func player(player: PlayerViewModel, willPlayVideo video: PlayableVideo) {
        vm.currentMessage.value = video as? MessageViewModel
    }
    
    func player(player: PlayerViewModel, didPlayVideo video: PlayableVideo) {
        vm.currentMessage.value = nil
        if let message = video as? MessageViewModel {
            vm.openMessage(message)
        }
    }
}
