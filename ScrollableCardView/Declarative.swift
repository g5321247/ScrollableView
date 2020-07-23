//
//  Declaritive.swift
//  TipVIewTest
//
//  Created by 劉峻岫 on 2020/7/23.
//  Copyright © 2020 addcn. All rights reserved.
//

import UIKit

protocol Declarative: AnyObject {
    init()
}

extension Declarative {
    init(configure: (Self) -> Void) {
        self.init()
        configure(self)
    }

    func configure(handler: (Self) -> Void) {
        handler(self)
    }
}

extension NSObject: Declarative {}
