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

        guard let apiUrl = URL(string: "\(serverUrl)getmaps/") else {
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
                        let geoArr = chattEntry[4]?.data(using: .utf8).flatMap {
                            try? JSONSerialization.jsonObject(with: $0) as? [Any]
                        }
                        _chatts.append(Chatt(username: chattEntry[0],
                                                message: chattEntry[1],
                                                id: UUID(uuidString: chattEntry[2] ?? ""),
                                                 timestamp: chattEntry[3],
                                                 altRow: idx % 2 == 0,
                                                 geodata: geoArr.map {
                            GeoData(lat: $0[0] as! Double,
                                    lon: $0[1] as! Double,
                                    place: $0[2] as! String,
                                    facing: $0[3] as! String,
                                    speed: $0[4] as! String)
                        }))
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
        var geoObj: Data?
        if let geodata = chatt.geodata {
            geoObj = try? JSONSerialization.data(withJSONObject: [geodata.lat, geodata.lon, geodata.place, geodata.facing, geodata.speed])
        }
        
        let jsonObj = ["username": chatt.username,
                       "message": chatt.message,
                       "geodata": (geoObj == nil) ? nil : String(data: geoObj!, encoding: .utf8)]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonObj) else {
            print("postChatt: jsonData serialization error")
            return
        }
                
        guard let apiUrl = URL(string: "\(serverUrl)postmaps/") else {
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
    private let nFields = 5 // Mirror(reflecting: Chatt()).children.count-1

    private let serverUrl = "https://24.199.89.71/"
}
