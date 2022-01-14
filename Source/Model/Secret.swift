//
//  Secret.swift
//  FBTT
//
//  Created by Christoph on 2/1/19.
//  Copyright © 2019 Verse Communications Inc. All rights reserved.
//

import Foundation
import SSB
import Bot

extension Secret {
    var identity: Identity { return self.id }
}

extension Secret: Equatable {
    public static func == (lhs: Secret, rhs: Secret) -> Bool {
        return lhs.id == rhs.id
    }
}
