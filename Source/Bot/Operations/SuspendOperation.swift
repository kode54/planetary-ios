//
//  SuspendOperation.swift
//  Planetary
//
//  Created by Martin Dutra on 5/12/20.
//  Copyright © 2020 Verse Communications Inc. All rights reserved.
//

import Foundation
import Logger
import Bot

class SuspendOperation: AsynchronousOperation {

    private(set) var error: Error?
    
    override func main() {
        Logger.shared.info("SuspendOperation started.")
        
        let configuredIdentity = AppConfiguration.current?.identity
        let loggedInIdentity = Bot.shared.identity
        guard loggedInIdentity != nil, loggedInIdentity == configuredIdentity else {
            Logger.shared.info("Not logged in. SuspendOperation finished.")
            self.error = BotError.notLoggedIn
            self.finish()
            return
        }
        
        Bot.shared.suspend()
        
        Logger.shared.info("SuspendOperation finished.")
        self.finish()
    }
    
}
