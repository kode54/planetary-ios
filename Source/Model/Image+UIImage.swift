//
//  Image+UIImage.swift
//  FBTT
//
//  Created by Christoph on 5/8/19.
//  Copyright © 2019 Verse Communications Inc. All rights reserved.
//

import Foundation
import UIKit
import Bot

extension Image {

    init(link: BlobIdentifier, jpegImage: UIImage, data: Data) {
        self.init(height: Int(jpegImage.size.height),
                  link: link,
                  size: data.count,
                  type: MIMEType.jpeg.rawValue,
                  width: Int(jpegImage.size.width))
    }
    
}
