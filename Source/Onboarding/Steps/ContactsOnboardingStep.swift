//
//  ContactsOnboardingStep.swift
//  FBTT
//
//  Created by Christoph on 7/16/19.
//  Copyright © 2019 Verse Communications Inc. All rights reserved.
//

import Foundation
import UIKit

class ContactsOnboardingStep: OnboardingStep {

    init() {
        super.init(.contacts)
    }

    override func customizeView() {
        self.view.hintLabel.text = Text.Onboarding.contactsHint.text
        self.view.secondaryButton.setText(.notNow)
        self.view.primaryButton.setText(.connect)
    }

    override func secondary() {
        self.next()
    }

    override func primary() {
        self.data.allowedContacts = true
        AppController.shared.alert(style: .alert,
                                   title: Text.ok.text,
                                   message: Text.Onboarding.contactsWIP.text)
        {
            [unowned self] in
            self.next()
        }
    }
}
