//
//  ChattStore.swift
//  swiftUIChatter
//
//  Created by BlessedAmulya Parmar on 1/29/25.
//


import Observation
import Dispatch
import Foundation

@Observable
final class ChattStore {
    
    func getChatts() {
        // only one outstanding retrieval
        synchronized.sync {
            guard !self.isRetrieving else {
                return
            }
            self.isRetrieving = true
        }

        guard let apiUrl = URL(string: "\(serverUrl)getchatts/") else {
            print("getChatts: Bad URL")
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            var request = URLRequest(url: apiUrl)
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept") // expect response in JSON
            request.httpMethod = "GET"

            URLSession.shared.dataTask(with: request) { data, response, error in
                defer { // allow subsequent retrieval
                    self.synchronized.async {
                        self.isRetrieving = false
                    }
                }
                guard let data = data, error == nil else {
                    print("getChatts: NETWORKING ERROR")
                    return
                }
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
            }.resume()
        }
    }

        func postChatt(_ chatt: Chatt, completion: @escaping () -> ()) {
        let jsonObj = ["username": chatt.username,
                       "message": chatt.message]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonObj) else {
            print("postChatt: jsonData serialization error")
            return
        }
                
        guard let apiUrl = URL(string: "\(serverUrl)postchatt/") else {
            print("postChatt: Bad URL")
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            var request = URLRequest(url: apiUrl)
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = jsonData

            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let _ = data, error == nil else {
                    print("postChatt: NETWORKING ERROR")
                    return
                }

                if let httpStatus = response as? HTTPURLResponse {
                    if httpStatus.statusCode != 200 {
                        print("postChatt: HTTP STATUS: \(httpStatus.statusCode)")
                        return
                    } else {
                        completion()
                    }
                }

            }.resume()
        }
    }
    
    static let shared = ChattStore() // create one instance of the class to be shared
    private init() {}                // and make the constructor private so no other
                                     // instances can be created

    private var isRetrieving = false
    private let synchronized = DispatchQueue(label: "synchronized", qos: .background)

    private(set) var chatts = [Chatt]()
    private let nFields = Mirror(reflecting: Chatt()).children.count-1

    private let serverUrl = "https://mada.eecs.umich.edu/"
}
