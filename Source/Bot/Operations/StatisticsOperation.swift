//
//  StatisticsOperation.swift
//  Planetary
//
//  Created by Martin Dutra on 6/30/20.
//  Copyright © 2020 Verse Communications Inc. All rights reserved.
//

import Foundation
import Logger
import Analytics
import Bot

class StatisticsOperation: AsynchronousOperation {

    private(set) var result: Result<Statistics, Error> = .failure(AppError.unexpected)

    override func main() {
        Logger.shared.info("RefreshOperation started.")
        let configuredIdentity = AppConfiguration.current?.identity
        let loggedInIdentity = Bot.shared.identity
        guard loggedInIdentity != nil, loggedInIdentity == configuredIdentity else {
            Logger.shared.info("Not logged in. RefreshOperation finished.")
            self.result = .failure(BotError.notLoggedIn)
            self.finish()
            return
        }
        Bot.shared.statistics { [weak self] statistics in
            Logger.shared.info("StatisticsOperation finished.")
            if let lastSyncDate = statistics.lastSyncDate {
                let minutesSinceLastSync = floor(lastSyncDate.timeIntervalSinceNow / 60)
                Logger.shared.debug("Last sync: \(minutesSinceLastSync) minutes ago")
            }
            if let lastRefreshDate = statistics.lastRefreshDate {
                let minutesSinceLastRefresh = floor(lastRefreshDate.timeIntervalSinceNow / 60)
                Logger.shared.debug("Last refresh: \(minutesSinceLastRefresh) minutes ago")
            }
            if statistics.repo.feedCount != -1 {
                Logger.shared.debug("Feed count: \(statistics.repo.feedCount)")
                Logger.shared.debug("Message count: \(statistics.repo.messageCount)")
                Logger.shared.debug("Published message count: \(statistics.repo.numberOfPublishedMessages)")
            }
            if statistics.db.lastReceivedMessage != -3 {
                let lastRxSeq = statistics.db.lastReceivedMessage
                Logger.shared.debug("Last received message: \(lastRxSeq)")
                if statistics.repo.feedCount != -1 {
                    let diff = statistics.repo.messageCount - 1 - lastRxSeq
                    Logger.shared.debug("Message diff: \(diff)")
                }
            }
            Logger.shared.debug("Peers: \(statistics.peer.count)")
            Logger.shared.debug("Connected peers: \(statistics.peer.connectionCount)")
            // TODO: Implement this again
            //Analytics.shared.identify(statistics: statistics)
            //Analytics.shared.trackBotDidStats(statistics: statistics)
            let currentNumberOfPublishedMessages = statistics.repo.numberOfPublishedMessages
            if let configuration = AppConfiguration.current,
                let botIdentity = Bot.shared.identity,
                let configIdentity = configuration.identity,
                botIdentity == configIdentity,
                currentNumberOfPublishedMessages > -1,
                configuration.numberOfPublishedMessages <= currentNumberOfPublishedMessages {
                configuration.numberOfPublishedMessages = currentNumberOfPublishedMessages
                configuration.apply()
                var appConfigurations = AppConfigurations.current
                if let index = appConfigurations.firstIndex(of: configuration) {
                    appConfigurations[index] = configuration
                }
                appConfigurations.save()
            }
            self?.result = .success(statistics)
            self?.finish()
        }
    }

}
