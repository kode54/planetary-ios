//
//  SendMissionOperation.swift
//  Planetary
//
//  Created by Martin Dutra on 8/17/20.
//  Copyright © 2020 Verse Communications Inc. All rights reserved.
//

import Foundation
import Logger
import Monitor
import Bot

/// Attempts connection to a Planetary's pub. It redeems invitation to these pubs if the user
/// didn't do it previously.
class SendMissionOperation: AsynchronousOperation {
    
    enum MissionQuality {
        case low
        case high
    }
    
    /// Switches how many connections are made and how many retries are considered
    var quality: MissionQuality
    
    /// Result of the operation
    private(set) var result: Result<Void, Error> = .failure(AppError.unexpected)
    
    /// Minimum number of Planetary's pubs the users must have been invited to
    private static let minNumberOfStars = 3
    
    /// Internal operation queue meant for executing other operations
    private let operationQueue = OperationQueue()
    
    init(quality: MissionQuality) {
        self.quality = quality
        super.init()
    }
    
    override func main() {
        Logger.shared.info("SendMissionOperation started.")
        
        let configuredIdentity = AppConfiguration.current?.identity
        let loggedInIdentity = Bot.shared.identity
        guard loggedInIdentity != nil, loggedInIdentity == configuredIdentity else {
            Logger.shared.info("Not logged in. SendMissionOperation finished.")
            self.result = .failure(BotError.notLoggedIn)
            self.finish()
            return
        }
        
        let knownStars = Set(Environment.Constellation.stars)
        let knownStarsAddresses = knownStars.map { $0.address }
        
        Logger.shared.debug("Seeding known stars stars...")
        Bot.shared.seedPubAddresses(addresses: knownStarsAddresses) { [weak self, quality] result in
            Logger.shared.debug("Retrieving list of available stars...")
            Bot.shared.pubs { (pubs, error) in
                Logger.shared.optional(error)
                Monitor.shared.reportIfNeeded(error: error)
                
                if let error = error {
                    Logger.shared.info("Couldn't get list of available stars. SendMissionOperation finished.")
                    self?.result = .failure(error)
                    self?.finish()
                    return
                }
                
                // Get the stars the users already redeemed an invite to
                let availableStars = knownStars.filter { star in
                    pubs.contains { (pub) -> Bool in
                        pub.address.key == star.feed
                    }
                }
                
                let starsToSync: Set<Star>
                let redeemInviteOperations: [RedeemInviteOperation]
                
                // Check if the current number of available stars is enough
                let numberOfMissingStars = SendMissionOperation.minNumberOfStars - availableStars.count
                if numberOfMissingStars > 0 {
                    Logger.shared.debug("There are \(numberOfMissingStars) missing stars.")
                    
                    // Let's take a random set of stars to reach the minimum and create Redeem Invite
                    // operations
                    let missingStars = knownStars.subtracting(availableStars)
                    let randomSampleOfStars = missingStars.randomSample(UInt(numberOfMissingStars))
                    redeemInviteOperations = randomSampleOfStars.map {
                        return RedeemInviteOperation(star: $0, shouldFollow: false)
                    }
                    
                    // Lets sync to available stars and newly redeemed stars
                    starsToSync = availableStars.union(missingStars)
                } else {
                    Logger.shared.debug("There are \(availableStars.count) available stars.")
                    
                    // No need to redeem invite
                    redeemInviteOperations = []
                    
                    // Just sync to the available stars
                    starsToSync = availableStars
                }
                
                let syncOperation = SyncOperation(peers: starsToSync.map { $0.toPeer() })
                switch quality {
                case .low:
                    syncOperation.notificationsOnly = true
                case .high:
                    syncOperation.notificationsOnly = false
                }
                redeemInviteOperations.forEach { syncOperation.addDependency($0) }
                
                let operations = redeemInviteOperations + [syncOperation]
                self?.operationQueue.addOperations(operations, waitUntilFinished: true)
                
                Logger.shared.info("SendMissionOperation finished.")
                self?.result = .success(())
                self?.finish()
            }
        }
    }
}
