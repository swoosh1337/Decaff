//
//  Item.swift
//  Decaff
//
//  Created by Tazi Grigolia on 11/5/24.
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