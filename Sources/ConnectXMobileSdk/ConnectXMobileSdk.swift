// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import UIKit
import Network

enum ConnectXError: Error {
    case invalidURL
    case serializationFailed(Error)
    case networkRequestFailed(Error)
    case invalidResponse
    case invalidStatusCode(Int)
    case noData
}

public class ConnectXManager {
    public static let shared = ConnectXManager()
    
    private var generateCookieUrl = "https://backend.connect-x.tech/connectx/api/webtracking/generateCookie"
    private var apiDomain = "https://backend.connect-x.tech/connectx/api"
    
    private var token: String = ""
    private var organizeId: String = ""
    private var appStartTime: Date = Date()
    private var userAgent: String = ""
    private var cookie: String = ""
    
    private init() {}
    
    // MARK: - Initialization
    public func initialize(token: String, organizeId: String, env: String? = nil) throws {
        guard !token.isEmpty else {
            throw NSError(domain: "ConnectXMobileSdk", code: 400, userInfo: [NSLocalizedDescriptionKey: "Token must not be empty."])
        }
        
        guard !organizeId.isEmpty else {
            throw NSError(domain: "ConnectXMobileSdk", code: 400, userInfo: [NSLocalizedDescriptionKey: "Organize ID must not be empty."])
        }
        
        self.token = token
        self.organizeId = organizeId
        // If subdomain is passed, override the URLs
        if let sub = env, !sub.isEmpty {
            let base = "https://backend-\(sub).connect-x.tech/connectx/api"
            self.apiDomain = base
            self.generateCookieUrl = "\(base)/webtracking/generateCookie"
        }
        
        // Set user agent
        let osName = UIDevice.current.systemName
        let osVersion = UIDevice.current.systemVersion
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "UnknownApp"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        
        self.userAgent = "\(appName)/\(appVersion) (\(osName); \(osVersion))"
        
        // Fetch initial cookie
        getUnknownId { cookieValue in
            self.cookie = cookieValue ?? ""
        }
    }
    
    private func getDeviceType() -> String {
        #if targetEnvironment(macCatalyst)
        return "Laptop"
        #else
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return "Mobile"
        case .pad:
            return "Tablet"
        default:
            return "Unknown"
        }
        #endif
    }
    
    func getNetworkType(completion: @escaping ([String: String]) -> Void) {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue.global(qos: .background)

        monitor.pathUpdateHandler = { path in
            var networkType: [String: String] = ["label": "Other", "value": "other"]

            if path.usesInterfaceType(.wifi) {
                networkType = ["label": "WiFi", "value": "wifi"]
            } else if path.usesInterfaceType(.cellular) {
                networkType = ["label": "Cellular", "value": "cellular"]
            }

            completion(networkType)
            monitor.cancel() // Stop monitoring after detecting network type
        }

        monitor.start(queue: queue)
    }
    
    private func mapDeviceIdentifierToProductName(identifier: String) -> String {
        switch identifier {
        // iPhone Models
        case "iPhone1,1": return "iPhone 2G"
        case "iPhone1,2": return "iPhone 3G/3GS"
        case "iPhone2,1": return "iPhone 4"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3": return "iPhone 4S"
        case "iPhone4,1": return "iPhone 5"
        case "iPhone5,1", "iPhone5,2": return "iPhone 5C"
        case "iPhone5,3", "iPhone5,4": return "iPhone 5S"
        case "iPhone6,1", "iPhone6,2": return "iPhone 6"
        case "iPhone7,1": return "iPhone 6 Plus"
        case "iPhone7,2": return "iPhone 6S"
        case "iPhone8,1": return "iPhone 6S Plus"
        case "iPhone8,2": return "iPhone 7"
        case "iPhone8,4": return "iPhone SE (1st generation)"
        case "iPhone9,1", "iPhone9,3": return "iPhone 7 Plus"
        case "iPhone9,2", "iPhone9,4": return "iPhone 8"
        case "iPhone10,1", "iPhone10,4": return "iPhone 8 Plus"
        case "iPhone10,2", "iPhone10,5": return "iPhone X"
        case "iPhone10,3", "iPhone10,6": return "iPhone X"
        case "iPhone11,2": return "iPhone XS"
        case "iPhone11,4", "iPhone11,6": return "iPhone XS Max"
        case "iPhone11,8": return "iPhone XR"
        case "iPhone12,1": return "iPhone 11"
        case "iPhone12,3": return "iPhone 11 Pro"
        case "iPhone12,5": return "iPhone 11 Pro Max"
        case "iPhone13,1": return "iPhone 12 Mini"
        case "iPhone13,2": return "iPhone 12"
        case "iPhone13,3": return "iPhone 12 Pro"
        case "iPhone13,4": return "iPhone 12 Pro Max"
        case "iPhone14,4": return "iPhone 13 Mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        
        // iPad Models
        case "iPad1,1": return "iPad 1st generation"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4": return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3": return "iPad 3rd generation"
        case "iPad3,4", "iPad3,5", "iPad3,6": return "iPad 4th generation"
        case "iPad6,11", "iPad6,12": return "iPad 5th generation"
        case "iPad7,5", "iPad7,6": return "iPad 6th generation"
        case "iPad7,11", "iPad7,12": return "iPad 7th generation"
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4": return "iPad Pro (11-inch) 1st generation"
        case "iPad8,9", "iPad8,10": return "iPad Pro (11-inch) 2nd generation"
        case "iPad8,5", "iPad8,6", "iPad8,7": return "iPad Pro (12.9-inch) 3rd generation"
        case "iPad8,11", "iPad8,12": return "iPad Pro (12.9-inch) 4th generation"
        case "iPad11,1", "iPad11,2": return "iPad Mini 5th generation"
        case "iPad11,3", "iPad11,4": return "iPad Air 3rd generation"
        case "iPad13,1", "iPad13,2": return "iPad Air 4th generation"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7": return "iPad Pro (11-inch) 3rd generation"
        case "iPad13,8", "iPad13,9": return "iPad Pro (12.9-inch) 5th generation"
        
        // iPod Models
        case "iPod1,1": return "iPod Touch 1st generation"
        case "iPod2,1": return "iPod Touch 2nd generation"
        case "iPod3,1": return "iPod Touch 3rd generation"
        case "iPod4,1": return "iPod Touch 4th generation"
        case "iPod5,1": return "iPod Touch 5th generation"
        case "iPod7,1": return "iPod Touch 6th generation"
        case "iPod9,1": return "iPod Touch 7th generation"
        
        // Apple Watch Models
        case "Watch1,1", "Watch1,2": return "Apple Watch 1st generation"
        case "Watch2,6", "Watch2,7": return "Apple Watch Series 1"
        case "Watch2,3", "Watch2,4": return "Apple Watch Series 2"
        case "Watch3,1", "Watch3,2", "Watch3,3", "Watch3,4": return "Apple Watch Series 3"
        case "Watch4,1", "Watch4,2", "Watch4,3", "Watch4,4": return "Apple Watch Series 4"
        case "Watch5,1", "Watch5,2", "Watch5,3", "Watch5,4": return "Apple Watch Series 5"
        case "Watch6,1", "Watch6,2", "Watch6,3", "Watch6,4": return "Apple Watch Series 6"
        case "Watch7,1", "Watch7,2", "Watch7,3", "Watch7,4": return "Apple Watch Series 7"
        case "Watch8,1", "Watch8,2", "Watch8,3", "Watch8,4": return "Apple Watch Series 8"
        
        // Default case if the identifier is unknown
        default: return "Unknown Device"
        }
    }
    
    private func getDeviceProductName() -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)

        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        return mapDeviceIdentifierToProductName(identifier: identifier)
    }
    
    // MARK: - Fetch Cookie
    public func getUnknownId(completion: @escaping (String?) -> Void) {
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
    private func getClientData(completion: @escaping ([String: Any]) -> Void) {
        let language = Locale.current.languageCode ?? "en"
        let osName = UIDevice.current.systemName
        let osVersion = UIDevice.current.systemVersion
        let device = UIDevice.current.model

        getNetworkType { networkType in
            let clientData: [String: Any] = [
                "cx_isBrowser": false,
                "cx_language": language,
                "cx_browserName": "",
                "cx_browserVersion": "",
                "cx_engineName": "Swift",
                "cx_engineVersion": osVersion,
                "cx_userAgent": self.userAgent,
                "cx_source": Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "UnknownApp",
                "cx_type": "Mobile App",
                "cx_fingerprint": UIDevice.current.identifierForVendor?.uuidString as Any,
                "cx_deviceId": UIDevice.current.identifierForVendor?.uuidString as Any,
                "cx_deviceType": self.getDeviceType(),
                "cx_networkType": networkType, // Now this will work
                "cx_os": osName,
                "cx_osVersion": osVersion,
                "device": device,
                "cx_appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
                "cx_appBuild": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
                "cx_libraryVersion": "1.0.5",
                "cx_libraryPlatform": "Swift",
                "cx_device": self.getDeviceProductName() ?? "Unknown",
                "cx_deviceManufacturer": "Apple",
                "cx_timespent": Int(Date().timeIntervalSince(self.appStartTime))
            ]
            completion(clientData)
        }
    }

    
    public func cxPost<T: Decodable>(
        endpoint: String,
        body: some Encodable,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        // ---- 1. ตั้งค่า Request ----
        guard let url = URL(string: "\(apiDomain)\(endpoint)") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") // หากมีการใช้ Token
        
        // เข้ารหัส (Encode) ข้อมูล Body
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(.failure(NetworkError.encodingFailed(error)))
            return
        }
        
        // ---- 2. สร้างและเริ่ม Network Task ----
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            //
            // --- 3. จัดการผลลัพธ์ที่ได้รับกลับมา ---
            // โค้ดในส่วนนี้จะทำงานบน Background Thread
            //
            
            // เช็ค Network Error พื้นฐาน (เช่น ไม่มีอินเทอร์เน็ต)
            if let error = error {
                completion(.failure(NetworkError.networkRequestFailed(error)))
                return
            }
            
            // เช็คว่า Response เป็น HTTP Response ที่ถูกต้อง
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            // เช็ค Status Code (ต้องเป็น 2xx)
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NetworkError.invalidStatusCode(httpResponse.statusCode)))
                return
            }
            
            // เช็คว่ามี Data ส่งกลับมาจริง
            guard let responseData = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            // --- 4. ถอดรหัส (Decode) ข้อมูลและส่งผลลัพธ์สุดท้าย ---
            do {
                let decodedObject = try JSONDecoder().decode(T.self, from: responseData)
                // สำเร็จ! ส่ง Object ที่ถอดรหัสแล้วกลับไป
                completion(.success(decodedObject))
            } catch {
                // ล้มเหลวในการถอดรหัส JSON
                completion(.failure(NetworkError.decodingFailed(error)))
            }
        }
        
        // สั่งให้ task เริ่มทำงาน
        task.resume()
    }
    
    // MARK: - Public API Methods
    public func cxTracking(body: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        
        getClientData { clientData in
            var requestBody = body
            requestBody["organizeId"] = self.organizeId
            requestBody.merge(clientData) { _, new in new }
            
            self.cxPost(endpoint: "/webtracking", data: requestBody, completion: completion)
        }
    }
    
    public func cxIdentify(body: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        // Get tracking data from the body
        var trackingData = body["tracking"] as? [String: Any] ?? [:]
        
        getClientData { clientData in
            // Merge client data with tracking data
            trackingData.merge(clientData) { _, new in new }
            
            // Add organizeId to tracking data
            trackingData["organizeId"] = self.organizeId
            
            // Prepare request body
            let requestBody: [String: Any] = [
                "key": body["key"]!,
                "customers": body["customers"]!,
                "tracking": trackingData,
                "form": body["form"] ?? [:],
                "options": body["options"] ?? [:]
            ]
            
            // Send request using cxPost method
            self.cxPost(endpoint: "/webtracking/dropform", data: requestBody, completion: completion)
        }
    }

    
    public func cxOpenTicket(body: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        var ticketData = body
        var tracking: [String: Any] = ["organizeId": organizeId]
        if var ticket = ticketData["ticket"] as? [String: Any] {
            ticket["organizeId"] = organizeId
            ticketData["ticket"] = ticket
        }
        
        getClientData { clientData in
            tracking.merge(clientData) { _, new in new }
            ticketData["tracking"] = tracking
            // Send request using cxPost method
            self.cxPost(endpoint: "/webtracking/dropformOpenTicket", data: ticketData, completion: completion)
        }
    }
    
    public func cxCreateRecord<ResponseModel: Decodable>(objectName: String, bodies: some Encodable) async throws -> ResponseModel {
        let endpoint = "/object/\(objectName)/composite"
        return try await cxPost(endpoint: endpoint, body: bodies)
    }
}
