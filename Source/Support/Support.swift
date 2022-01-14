//
//  Support.swift
//  Planetary
//
//  Created by Martin Dutra on 12/1/22.
//  Copyright © 2022 Verse Communications Inc. All rights reserved.
//

import Foundation

struct Support {

    static var shared: SupportService = {
        #if DEBUG
        return NullSupport()
        #else
        if CommandLine.arguments.contains("mock-support") {
            return NullSupport()
        } else {
            return ZendeskSupport()
        }
        #endif
    }()

}
