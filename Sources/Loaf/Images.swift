//
//  Images.swift
//  Loaf
//
//  Created by iOS Dev on 20.02.2023.
//  Copyright © 2023 Mat Schmid. All rights reserved.
//

import UIKit

enum Images {
    case xIcon
    case warningIcon
    case successIcon

    var image: UIImage {
        switch self {
        case.xIcon:
            return UIImage(named: "cancelIcon.png")!
        case .warningIcon:
            return UIImage(named: "warningIcon.png")!
        case .successIcon:
            return UIImage(named: "successIcon.png")!
        }
    }
}
