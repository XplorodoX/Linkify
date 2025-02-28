//
//  Item.swift
//  Linkify
//
//  Created by Florian Merlau on 28.02.25.
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
