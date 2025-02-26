//
//  ChattStore.swift
//  swiftUIChatter
//
//  Created by BlessedAmulya Parmar on 1/29/25.
//


import Observation
import Dispatch
import Foundation
import os

@Observable
final class ChattStore: @unchecked Sendable {
    
    func getChatts() async {
        // only one outstanding retrieval
        mutex.withLock {
            guard !self.isRetrieving else {
                return
            }
            self.isRetrieving = true
        }

        defer { // allow subsequent retrieval
            mutex.withLock {
                self.isRetrieving = false
            }
        }
        
        guard let apiUrl = URL(string: "\(serverUrl)getchatts/") else {
            print("getChatts: Bad URL")
            return
        }
        
        var request = URLRequest(url: apiUrl)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept") // expect response in JSON
        request.httpMethod = "GET"

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
                
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("getChatts: HTTP STATUS: \(httpStatus.statusCode)")
                return
            }
                
            guard let chattsReceived = try? JSONSerialization.jsonObject(with: data) as? [[String?]] else {
                print("getChatts: failed JSON deserialization")
                return
            }
            
            var idx = 0
            var _chatts = [Chatt]()
            for chattEntry in chattsReceived {
                if chattEntry.count == self.nFields {
                    _chatts.append(Chatt(username: chattEntry[0],
                                             message: chattEntry[1],
                                             id: UUID(uuidString: chattEntry[2] ?? ""),
                                             timestamp: chattEntry[3],
                                             altRow: idx % 2 == 0))
                    idx += 1
                } else {
                    print("getChatts: Received unexpected number of fields: \(chattEntry.count) instead of \(self.nFields).")
                }
            }
            self.chatts = _chatts
        } catch {
            print("getChatts: NETWORKING ERROR")
        }
    }

    func postChatt(_ chatt: Chatt) async -> Data? {
        let jsonObj = ["chatterID": ChatterID.shared.id,
                       "message": chatt.message]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonObj) else {
            print("postChatt: jsonData serialization error")
            return nil
        }
                
        guard let apiUrl = URL(string: "\(serverUrl)postauth/") else {
            print("postChatt: Bad URL")
            return nil
        }
        
        var request = URLRequest(url: apiUrl)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                print("postChatt: \(HTTPURLResponse.localizedString(forStatusCode: http.statusCode))")
            } else {
                return data
            }
        } catch {
            print("postChatt: NETWORKING ERROR")
        }
        return nil
    }
    
    func addUser(_ idToken: String?) async -> String? {
        guard let idToken else {
            return nil
        }
        
        let jsonObj = ["clientID": "764691104830-r1sgun4nvii575mfad2g0g84lcj749e9.apps.googleusercontent.com",
                    "idToken" : idToken]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonObj) else {
            print("addUser: jsonData serialization error")
            return nil
        }

        guard let apiUrl = URL(string: "\(serverUrl)adduser/") else {
            print("addUser: Bad URL")
            return nil
        }
        
        var request = URLRequest(url: apiUrl)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept") // expect response in JSON
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("addUser: HTTP STATUS: \(httpStatus.statusCode)")
                return nil
            }

            guard let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String:Any] else {
                print("addUser: failed JSON deserialization")
                return nil
            }

            ChatterID.shared.id = jsonObj["chatterID"] as? String
            ChatterID.shared.expiration = Date()+(jsonObj["lifetime"] as! TimeInterval)
            
            return ChatterID.shared.id
        } catch {
            print("addUser: NETWORKING ERROR")
            return nil
        }
    }
    
    static let shared = ChattStore() // create one instance of the class to be shared
    private init() {}                // and make the constructor private so no other
                                     // instances can be created

    private var isRetrieving = false
    private let mutex = OSAllocatedUnfairLock()

    private(set) var chatts = [Chatt]()
    private let nFields = Mirror(reflecting: Chatt()).children.count-1

    private let serverUrl = "https://24.199.89.71/"
}
