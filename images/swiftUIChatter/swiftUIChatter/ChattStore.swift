//
//  ChattStore.swift
//  swiftUIChatter
//
//  Created by BlessedAmulya Parmar on 1/29/25.
//

import UIKit
import Alamofire
import Observation
import Dispatch
import Foundation
import os

@Observable
final class ChattStore: @unchecked Sendable {
    
    func getChatts() {
        // Only one outstanding retrieval
        mutex.lock()
        guard !self.isRetrieving else {
            mutex.unlock()
            return
        }
        self.isRetrieving = true
        mutex.unlock()

        guard let apiUrl = URL(string: "\(serverUrl)getimages/") else {
            print("getChatts: bad URL")
            return
        }
        
        AF.request(apiUrl, method: .get).responseData { response in
            guard let data = response.data, response.error == nil else {
                print("getChatts: NETWORKING ERROR")
                return
            }
            if let httpStatus = response.response, httpStatus.statusCode != 200 {
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
                                         altRow: idx % 2 == 0,
                                         imageUrl: chattEntry[4],
                                         videoUrl: chattEntry[5]))
                    idx += 1
                } else {
                    print("getChatts: Received unexpected number of fields: \(chattEntry.count) instead of \(self.nFields).")
                }
            }
            self.chatts = _chatts
            self.mutex.lock()
            self.isRetrieving = false
            self.mutex.unlock()
        }
    }

    func postChatt(_ chatt: Chatt, image: UIImage?, videoUrl: URL?) async -> Data? {
        guard let apiUrl = URL(string: "\(serverUrl)postimages/") else {
            print("postChatt: Bad URL")
            return nil
        }
                
        return try? await AF.upload(multipartFormData: { mpFD in
            if let username = chatt.username?.data(using: .utf8) {
                mpFD.append(username, withName: "username")
            }
            if let message = chatt.message?.data(using: .utf8) {
                mpFD.append(message, withName: "message")
            }
            if let jpegImage = image?.jpegData(compressionQuality: 1.0) {
                mpFD.append(jpegImage, withName: "image", fileName: "chattImage", mimeType: "image/jpeg")
            }
            if let videoUrl {
                mpFD.append(videoUrl, withName: "video", fileName: "chattVideo", mimeType: "video/mp4")
            }
        }, to: apiUrl, method: .post).validate().serializingData().value
    }
    
    func addUser(_ idToken: String?) async -> String? {
        guard let idToken else {
            return nil
        }
        
        let jsonObj = ["clientID": "764691104830-r1sgun4nvii575mfad2g0g84lcj749e9.apps.googleusercontent.com",
                       "idToken": idToken]

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
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("addUser: HTTP STATUS: \(httpStatus.statusCode)")
                return nil
            }

            guard let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("addUser: failed JSON deserialization")
                return nil
            }

            ChatterID.shared.id = jsonObj["chatterID"] as? String
            ChatterID.shared.expiration = Date() + (jsonObj["lifetime"] as! TimeInterval)
            
            return ChatterID.shared.id
        } catch {
            print("addUser: NETWORKING ERROR")
            return nil
        }
    }
    
    static let shared = ChattStore()
    private init() {}

    private var isRetrieving = false
    private let mutex = OSAllocatedUnfairLock()

    private(set) var chatts = [Chatt]()
    private let nFields = 6 //Mirror(reflecting: Chatt()).children.count

    private let serverUrl = "https://24.199.89.71/"
}
