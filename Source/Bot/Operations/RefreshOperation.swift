//
//  RefreshOperation.swift
//  Planetary
//
//  Created by Martin Dutra on 4/27/20.
//  Copyright © 2020 Verse Communications Inc. All rights reserved.
//

import Foundation
import Logger
import Monitor
import Analytics
import Bot

class RefreshOperation: AsynchronousOperation {

    var refreshLoad: RefreshLoad = .short
    private(set) var error: Error?
    
    convenience init(refreshLoad: RefreshLoad) {
        self.init()
        self.refreshLoad = refreshLoad
    }
    
    override func main() {
        Logger.shared.info("RefreshOperation started.")
        
        let configuredIdentity = AppConfiguration.current?.identity
        let loggedInIdentity = Bot.shared.identity
        guard loggedInIdentity != nil, loggedInIdentity == configuredIdentity else {
            Logger.shared.info("Not logged in. RefreshOperation finished.")
            self.error = BotError.notLoggedIn
            self.finish()
            return
        }
        
        Bot.shared.refresh(load: refreshLoad) { [weak self, refreshLoad] (error, timeInterval) in
            Analytics.shared.trackBotDidRefresh(load: refreshLoad.rawValue, duration: timeInterval, error: error)
            Logger.shared.optional(error)
            Monitor.shared.reportIfNeeded(error: error)
            
            Logger.shared.info("RefreshOperation finished. Took \(timeInterval) seconds to refresh.")
            if let strongSelf = self, !strongSelf.isCancelled {
                self?.error = error
            }
            self?.finish()
        }
    }
    
}
