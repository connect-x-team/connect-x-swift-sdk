// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import UIKit

public class ConnectXMobileSdk {
    public static let shared = ConnectXMobileSdk()
    
    private let apiDomain = "https://connect-x-poon-beta-2-4a43443547d7.herokuapp.com/connectx/api"
    private let generateCookieUrl = "https://connect-x-poon-beta-2-4a43443547d7.herokuapp.com/connectx/api/webtracking/generateCookie"
    
    private var token: String = ""
    private var organizeId: String = ""
    private var appStartTime: Date = Date()
    private var userAgent: String = ""
    private var cookie: String = ""
    
    private init() {}
    
    // MARK: - Initialization
    public func initialize(token: String, organizeId: String) throws {
        guard !token.isEmpty else {
            throw NSError(domain: "ConnectXMobileSdk", code: 400, userInfo: [NSLocalizedDescriptionKey: "Token must not be empty."])
        }
        
        guard !organizeId.isEmpty else {
            throw NSError(domain: "ConnectXMobileSdk", code: 400, userInfo: [NSLocalizedDescriptionKey: "Organize ID must not be empty."])
        }
        
        self.token = token
        self.organizeId = organizeId
        
        // Set user agent
        let osName = UIDevice.current.systemName
        let osVersion = UIDevice.current.systemVersion
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "UnknownApp"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        
        self.userAgent = "\(appName)/\(appVersion) (\(osName); \(osVersion))"
        
        // Fetch initial cookie
        fetchCookie { cookieValue in
            self.cookie = cookieValue ?? ""
        }
    }
    
    // MARK: - Fetch Cookie
    private func fetchCookie(completion: @escaping (String?) -> Void) {
        guard let url = URL(string: generateCookieUrl) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to fetch cookie: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data, let cookie = String(data: data, encoding: .utf8) else {
                completion(nil)
                return
            }
            
            completion(cookie)
        }
        
        task.resume()
    }
    
    // MARK: - Get Client Data
    private func getClientData() -> [String: Any] {
        let language = Locale.current.languageCode ?? "en"
        let osName = UIDevice.current.systemName
        let osVersion = UIDevice.current.systemVersion
        let device = UIDevice.current.model
        
        return [
            "cx_isBrowser": false,
            "cx_language": language,
            "cx_browserName": "",
            "cx_browserVersion": "",
            "cx_engineName": "Swift",
            "cx_engineVersion": osVersion,
            "cx_userAgent": userAgent,
            "cx_source": Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "UnknownApp",
            "cx_type": "Mobile App",
            "cx_fingerprint": UUID().uuidString,
            "os": osName,
            "osVersion": osVersion,
            "device": device,
            "cx_cookie": cookie,
            "cx_timespent": Int(Date().timeIntervalSince(appStartTime))
        ]
    }
    
    // MARK: - Generic Post Request
    private func cxPost(endpoint: String, data: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        guard let url = URL(string: "\(apiDomain)\(endpoint)") else {
            completion(false, NSError(domain: "ConnectXMobileSdk", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL."]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: data, options: [])
        } catch {
            completion(false, error)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(false, error)
                return
            }
            completion(true, nil)
        }
        
        task.resume()
    }
    
    // MARK: - Public API Methods
    public func cxTracking(body: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        let clientData = getClientData()
        var requestBody = body
        requestBody["organizeId"] = organizeId
        requestBody.merge(clientData) { _, new in new }
        
        cxPost(endpoint: "/webtracking", data: requestBody, completion: completion)
    }
    
    public func cxIdentify(key: String, customers: [String: Any], tracking: [String: Any], form: [String: Any]?, options: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        var trackingData = tracking
        trackingData.merge(getClientData()) { _, new in new }
        trackingData["organizeId"] = organizeId
        
        let requestBody: [String: Any] = [
            "key": key,
            "customers": customers,
            "tracking": trackingData,
            "form": form ?? [:],
            "options": options
        ]
        
        cxPost(endpoint: "/webtracking/dropform", data: requestBody, completion: completion)
    }
    
    public func cxOpenTicket(body: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        var ticketData = body
        ticketData["organizeId"] = organizeId
        
        cxPost(endpoint: "/webtracking/dropformOpenTicket", data: ticketData, completion: completion)
    }
    
    public func cxCreateObject(objectName: String, bodies: [[String: Any]], completion: @escaping (Bool, Error?) -> Void) {
        cxPost(endpoint: "/object/\(objectName)/composite", data: ["bodies": bodies], completion: completion)
    }
}
