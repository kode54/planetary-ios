//
//  FollowOperation.swift
//  Planetary
//
//  Created by Martin Dutra on 8/13/20.
//  Copyright © 2020 Verse Communications Inc. All rights reserved.
//

import Foundation
import Logger
import Monitor
import Bot

class FollowOperation: AsynchronousOperation {

    var identity: Identity
    private(set) var error: Error?
    
    init(identity: Identity) {
        self.identity = identity
        super.init()
    }
    
    override func main() {
        Logger.shared.info("FollowOperation started.")
        
        let configuredIdentity = AppConfiguration.current?.identity
        let loggedInIdentity = Bot.shared.identity
        guard loggedInIdentity != nil, loggedInIdentity == configuredIdentity else {
            Logger.shared.info("Not logged in. FollowOperation finished.")
            self.error = BotError.notLoggedIn
            self.finish()
            return
        }
        
        Bot.shared.follow(self.identity) { [weak self] (contact, error) in
            Logger.shared.optional(error)
            Monitor.shared.reportIfNeeded(error: error)
            self?.error = error
            Logger.shared.info("FollowOperation finished.")
            self?.finish()
        }
    }
    
}
