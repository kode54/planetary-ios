//
//  LoadBundleOperation.swift
//  Planetary
//
//  Created by Martin Dutra on 6/3/20.
//  Copyright © 2020 Verse Communications Inc. All rights reserved.
//

import Foundation
import Logger
import Bot

class LoadBundleOperation: AsynchronousOperation {

    var bundle: Bundle
    private(set) var error: Error?
    
    init(bundle: Bundle) {
        self.bundle = bundle
        super.init()
    }
    

    override func main() {
        Logger.shared.info("LoadBundleOperation started.")
        
        let configuredIdentity = AppConfiguration.current?.identity
        let loggedInIdentity = Bot.shared.identity
        guard loggedInIdentity != nil, loggedInIdentity == configuredIdentity else {
            Logger.shared.info("Not logged in. LoadBundleOperation finished.")
            self.error = BotError.notLoggedIn
            self.finish()
            return
        }
        
        let group = DispatchGroup()
        
        let feedPaths = bundle.paths(forResourcesOfType: "json", inDirectory: "Feeds")
        feedPaths.forEach { path in
            group.enter()
            let url = URL(fileURLWithPath: path)
            Logger.shared.info("Preloading feed \(url.lastPathComponent)...")
            Bot.shared.preloadFeed(at: url) { (error) in
                if let error = error {
                    Logger.shared.info("Preloading feed \(url.lastPathComponent) failed with error: \(error.localizedDescription).")
                } else {
                    Logger.shared.info("Feed \(url.lastPathComponent) was preloaded successfully.")
                }
                group.leave()
            }
        }
        
        let blobIdentifiersPath = bundle.path(forResource: "BlobIdentifiers", ofType: "plist")!
        let xml = FileManager.default.contents(atPath: blobIdentifiersPath)!
        var format = PropertyListSerialization.PropertyListFormat.xml
        let blobIdentifiers = try! PropertyListSerialization.propertyList(from: xml,
                                                                          options: .mutableContainersAndLeaves,
                                                                          format: &format) as! [String: String]
        
        let blobPaths  = bundle.paths(forResourcesOfType: nil, inDirectory: "Blobs")
        blobPaths.forEach { path in
            group.enter()
            let url = URL(fileURLWithPath: path)
            let identifier = blobIdentifiers[url.lastPathComponent]!
            Logger.shared.info("Preloading blob \(identifier)...")
            Bot.shared.store(url: url, for: identifier) { (_, error) in
                if let error = error {
                    Logger.shared.info("Preloading blob \(identifier) failed with error: \(error.localizedDescription).")
                } else {
                    Logger.shared.info("Blob \(identifier) was preloaded successfully.")
                }
                group.leave()
            }
        }
        
        group.wait()
        
        self.finish()
    }
    
}
