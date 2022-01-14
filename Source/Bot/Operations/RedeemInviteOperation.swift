//
//  RedeemInviteOperation.swift
//  Planetary
//
//  Created by Martin Dutra on 8/12/20.
//  Copyright © 2020 Verse Communications Inc. All rights reserved.
//

import Foundation
import Logger
import Monitor
import Bot

class RedeemInviteOperation: AsynchronousOperation {

    /// Star that you want to redeem invitation to
    var star: Star
    
    /// If true, it will automatically follow the star
    var shouldFollow: Bool
    
    /// Result of the operation
    private(set) var result: Result<Void, Error>?
    
    init(star: Star, shouldFollow: Bool) {
        self.star = star
        self.shouldFollow = shouldFollow
        super.init()
    }
    
    override func main() {
        Logger.shared.info("RedeemInviteOperation started.")
        let configuredIdentity = AppConfiguration.current?.identity
        let loggedInIdentity = Bot.shared.identity
        guard loggedInIdentity != nil, loggedInIdentity == configuredIdentity else {
            Logger.shared.info("Not logged in. RedeemInviteOperation finished.")
            self.result = .failure(BotError.notLoggedIn)
            self.finish()
            return
        }
        Logger.shared.debug("Redeeming invite to star \(self.star.feed)...")
        Bot.shared.inviteRedeem(token: self.star.invite) { [weak self, star, shouldFollow] (error) in
            Logger.shared.optional(error)
            Monitor.shared.reportIfNeeded(error: error)
            if let error = error {
                Logger.shared.info("RedeemInviteOperation to \(star.feed) finished with error \(error).")
                self?.result = .failure(error)
                self?.finish()
            } else {
                Logger.shared.debug("Publishing Pub (\(star.feed)) message...")
                let pub = star.toPub()
                Bot.shared.publish(content: pub) { (_, error) in
                    Logger.shared.optional(error)
                    Monitor.shared.reportIfNeeded(error: error)
                    if let error = error {
                        Logger.shared.info("Publishing Pub \(star.feed) message finished with error \(error).")
                        // We don't care the result, move on
                    }
                    if shouldFollow {
                        Logger.shared.debug("Publishing Contact (\(star.feed)) message...")
                        let contact = Contact(contact: star.feed, following: true)
                        Bot.shared.publish(content: contact) { (_, error) in
                            Logger.shared.optional(error)
                            Monitor.shared.reportIfNeeded(error: error)
                            if let error = error {
                                Logger.shared.info("RedeemInviteOperation to \(star.feed) finished with error \(error).")
                                self?.result = .failure(error)
                                self?.finish()
                            } else {
                                Logger.shared.info("RedeemInviteOperation to \(star.feed) finished.")
                                self?.result = .success(())
                                self?.finish()
                            }
                        }
                    } else {
                        Logger.shared.info("RedeemInviteOperation to \(star.feed) finished.")
                        self?.result = .success(())
                        self?.finish()
                    }
                }
            }
        }
    }
    
}
