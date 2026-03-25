//
//  Item.swift
//  DoorsApp
//
//  Created by Wesley Brito on 25/03/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
