//
//  String+PhoneNumberKit.swift
//  FBTT
//
//  Created by Christoph on 7/15/19.
//  Copyright © 2019 Verse Communications Inc. All rights reserved.
//

import Foundation
import PhoneNumberKit

extension String {

    static private let phoneNumberKit = PhoneNumberKit()

    func phoneNumber() -> PhoneNumber? {
        return try? String.phoneNumberKit.parse(self)
    }

    var isValidPhoneNumber: Bool {
        return self.phoneNumber() != nil
    }
}
