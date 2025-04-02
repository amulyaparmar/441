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
    var geodata: GeoData?
    @OptionalizedEmpty var audio: String?
    @OptionalizedEmpty var imageUrl: String?
    @OptionalizedEmpty var videoUrl: String?
    
    // so that we don't need to compare every property for equality
    static func ==(lhs: Chatt, rhs: Chatt) -> Bool {
        lhs.id == rhs.id
    }    
}

@propertyWrapper
struct OptionalizedEmpty {
    private var _value: String?
    var wrappedValue: String? {
        get { _value }
        set {
            guard let newValue else {
                _value = nil
                return
            }
            _value = (newValue == "null" || newValue.isEmpty) ? nil : newValue
        }
    }
    
    init(wrappedValue: String?) {
        self.wrappedValue = wrappedValue
    }
}
