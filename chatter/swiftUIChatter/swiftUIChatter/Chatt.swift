//
//  Chatt.swift
//  swiftUIChatter
//
//  Created by BlessedAmulya Parmar on 1/29/25.
//


import Foundation

struct Chatt: Identifiable {
    var username: String?
    var message: String?
    var id: UUID?
    var timestamp: String?
    var altRow = true

    // so that we don't need to compare every property for equality
    static func ==(lhs: Chatt, rhs: Chatt) -> Bool {
        lhs.id == rhs.id
    }    
}
