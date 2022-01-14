//
//  ExitOperation.swift
//  Planetary
//
//  Created by Martin Dutra on 5/12/20.
//  Copyright © 2020 Verse Communications Inc. All rights reserved.
//

import Foundation
import Logger
import Bot

class ExitOperation: AsynchronousOperation {

    private(set) var error: Error?
    
    override func main() {
        Logger.shared.info("ExitOperation started.")
        
        let configuredIdentity = AppConfiguration.current?.identity
        let loggedInIdentity = Bot.shared.identity
        guard loggedInIdentity != nil, loggedInIdentity == configuredIdentity else {
            Logger.shared.info("Not logged in. ExitOperation finished.")
            self.error = BotError.notLoggedIn
            self.finish()
            return
        }
        
        Bot.shared.exit()
        
        Logger.shared.info("ExitOperation finished.")
        self.finish()
    }
    
}
