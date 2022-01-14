//
//  Root.swift
//  FBTT
//
//  Created by Christoph on 2/4/19.
//  Copyright © 2019 Verse Communications Inc. All rights reserved.
//

import Foundation
import SSB

// MARK:- Specific keys subclasses

class NetworkKey: DataKey {

    // SSB default network
    static let ssb = NetworkKey(base64: Environment.DefaultNetwork.key)!

    // Verse development network
    // Generated from "Verse Communications, Inc." string
    static let verse = NetworkKey(base64: Environment.DevelopmentNetwork.key)!

    // Verse testing network
    // auto-deploy network for CI testing, will be scrubbed
    static let integrationTests = NetworkKey(base64: Environment.TestingNetwork.key)!
    
    // Planetary develpoment network for the new format
    static let planetary = NetworkKey(base64: Environment.PlanetaryNetwork.key)!

    var name: String {
        if self == NetworkKey.ssb { return Environment.DefaultNetwork.name }
        else if self == NetworkKey.integrationTests { return Environment.TestingNetwork.name }
        else if self == NetworkKey.planetary { return Environment.PlanetaryNetwork.name }
        else { return Environment.DevelopmentNetwork.name }
    }
}

class HMACKey: DataKey {

    // SSB default network
    // there is no HMAC key for the SSB network

    // development network
    static let verse = HMACKey(base64: Environment.DevelopmentNetwork.hmac)!
    
    // automated testing network
    static let integrationTests = HMACKey(base64: Environment.TestingNetwork.hmac)!

    // Next HMAC key
    static let planetary = HMACKey(base64: Environment.PlanetaryNetwork.hmac)!
}
