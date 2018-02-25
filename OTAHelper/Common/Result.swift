//
//  Result.swift
//  OTAHelper
//
//  Created by Watanabe Toshinori on 2/25/18.
//  Copyright © 2018 Watanabe Toshinori. All rights reserved.
//

import Cocoa

enum Result<T: Any> {
    case success(T)
    case failure(Error)
}
