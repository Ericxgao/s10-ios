//
//  AccountService.swift
//  Taylr
//
//  Created by Tony Xiao on 2/3/15.
//  Copyright (c) 2015 S10 Inc. All rights reserved.
//

import Foundation
import ReactiveCocoa
import DigitsKit
import Core

extension Digits {
    func authenticate() -> Future<DGTSession, NSError> {
        let promise = Promise<DGTSession, NSError>()
        authenticateWithCompletion { (session: DGTSession?, error: NSError?) in
            if let session = session {
                promise.success(session)
            } else if let error = error where error.code == DGTErrorCode.UserCanceledAuthentication.rawValue {
                promise.cancel()
            } else if let error = error {
                promise.failure(error)
            } else {
                assertionFailure("Should either succeed or fail")
            }
        }
        return promise.future
    }
}

class AccountService {
    private let meteorService: MeteorService
    private let _digitsSession: MutableProperty<DGTSession?>
    let digits = Digits.sharedInstance()
    let state: PropertyOf<AccountState>
    let digitsSession: PropertyOf<DGTSession?>
    
    init(meteorService: MeteorService) {
        self.meteorService = meteorService
        let settings = meteorService.currentUser
        _digitsSession = MutableProperty(digits.session())
        digitsSession = PropertyOf(_digitsSession)
        state = PropertyOf(.Indeterminate) {
            combineLatest(
                meteorService.account.producer,
                meteorService.loggedIn.producer,
                settings.accountStatus.producer,
                settings.networkRequired.producer
            ).map { account, loggedIn, status, networkRequired in
                switch (account, loggedIn, status, networkRequired) {
                case (.None, _, _, _):
                    Log.info("Status - Logged Out")
                    return .LoggedOut
                case (.Some, true, .Some(.Pending), .Some(true)):
                    Log.info("Status - Logged In")
                    return .LoggedIn
                case (.Some, true, .Some(.Pending), .Some(false)):
                    Log.info("Status - Logged In, but not requiring network")
                    return .LoggedInButCodeDisabled
                case (.Some, true, .Some(.Active), _):
                    Log.info("Status - Signed Up")
                    return .Onboarded
                default:
                    Log.info("Status - Indeterminate")
                    return .Indeterminate
                }
            }.map { (state: AccountState) -> AccountState in
                if state != .Indeterminate {
                    UD.accountState.value = state.rawValue
                    return state
                } else {
                    return UD.accountState.value.flatMap { AccountState(rawValue: $0) } ?? .Indeterminate
                }
            }
        }
    }
    
    func hasAccount() -> Bool {
        return digits.session() != nil && meteorService.account.value != nil
    }
    
    // MARK: -
    
    func login() -> Future<AccountState, NSError> {
        let promise = Promise<AccountState, NSError>()
        digits.authenticate()
           .deliverOn(UIScheduler())
           .onComplete {
                self._digitsSession.value = $0.value
                print("Session userId= \($0.value?.userID) error \($0.error)")
                if let session = $0.value {
                    self.meteorService.loginWithDigits(
                        userId: session.userID,
                        authToken: session.authToken,
                        authTokenSecret: session.authTokenSecret,
                        phoneNumber: session.phoneNumber
                    ).onFailure {
                        promise.failure($0)
                    }.onSuccess {
                        promise.success(self.state.value)
                    }
                } else {
                    promise.failure($0.error!)
                }
            }
           .onCancel { promise.cancel() }
        return promise.future
    }
    
    func logout() {
        UD.resetAll()
        digits.logOut()
        _digitsSession.value = nil
        meteorService.logout()
    }
    
}

extension AccountService : LoginDelegate {
    var loggedInPhone: PropertyOf<String?> {
        return _digitsSession.map { $0?.phoneNumber }
    }
}
