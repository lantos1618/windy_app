//
//  LicenseManager.swift
//  windy
//
//  Created by Lyndon Leong on 29/05/2023.
//

import Foundation
import IOKit
import SwiftUI


struct LicenseForm: View {
    @StateObject var windyData      : WindyData
    var licenseManager : LicenseManager
    @State private var showingAlert = false
    @State private var alertTitle   = ""
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            TextField("Email", text: $windyData.email)
            TextField("License Key", text: $windyData.licenseKey)
            HStack{
                Button("Close") {
                    self.licenseManager.closeLicenseForm()
                }
                Button("Verify License") {
                    self.licenseManager.verifyLicense()
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }

            }
        }.padding()
    }
}



class LicenseManager {
    private let windyData           : WindyData
    private var verificationTimer   : Timer?
    private let verificationInterval: TimeInterval = 60.0 // Set to desired interval in seconds
    private let gracePeriod         : TimeInterval = 60.0 * 60.0 * 24.0 // 24 hours for example
    private var lastSuccessfulVerification: Date? = nil
    private static let licenseServer = "http://localhost:3000"
    private static let licenseURI    =  "/api/licenseHeartbeat"
    let licenseURL = URL(string: licenseServer + licenseURI)!
    
    private var licenseWindow: NSWindow?
    
    init(windyData: WindyData) {
        self.windyData = windyData
    }
    
    func closeLicenseForm() {
        self.licenseWindow?.close()
        self.licenseWindow = nil  
    }
    
    func displayLicenseForm() {
        // check to see if window is avaliable
        if (self.licenseWindow != nil) {
            if(self.licenseWindow!.isVisible == false) {
                self.licenseWindow?.setIsVisible(true);
                return
            }
            return
        }
        
        // create the license window and show it
        
        self.licenseWindow = NSWindow(
            contentRect : NSRect(x: 0, y: 0, width: 400, height: 380),
            styleMask   : [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing     : .buffered,
            defer       : false
        )
        
        let licenseForm = LicenseForm(windyData: self.windyData, licenseManager: self)
        self.licenseWindow?.contentView          = NSHostingView(rootView: licenseForm)
        self.licenseWindow?.collectionBehavior = .canJoinAllSpaces
        self.licenseWindow?.isReleasedWhenClosed = false
        self.licenseWindow?.setIsVisible(true)
        self.licenseWindow?.center()
        self.licenseWindow?.makeKeyAndOrderFront(nil)
    }
    
    func getComputerId() -> String? {
        var serialNumber: String? = nil
        let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        if platformExpert != 0 {
            let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0)
            IOObjectRelease(platformExpert)
            if let serialNumberAsCFString = serialNumberAsCFString {
                serialNumber = serialNumberAsCFString.takeRetainedValue() as? String
            }
        }
        return serialNumber
    }

    
    func sendHeartbeat(licenseKey: String, email: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let computerId = getComputerId() else {
            // Handle error: Could not get computer id
            return
        }
        
        if (licenseKey == "") {
            displayLicenseForm()
            return
        }
        
        var request = URLRequest(url: licenseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
   
        let body = [
            "licenseKey" : licenseKey,
            "email"      : email,
            "computerId" : computerId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = data {
                do {
                    if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = jsonObject["message"] as? String {
                        completion(.success(message))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    
    func startHeartbeat() {
        self.verifyLicense()
        self.verificationTimer = Timer.scheduledTimer(withTimeInterval: verificationInterval, repeats: true) { [weak self] _ in
            self?.verifyLicense()
        }
    }

    func pauseHeartbeat() {
        guard let timer = self.verificationTimer else {
            return // already paused
        }
        if(timer.isValid) {
            self.verificationTimer?.invalidate()
        }
    }
    
    func verifyLicense() {
        debugPrint("verifying license")
        sendHeartbeat(
            licenseKey: windyData.licenseKey,
            email: windyData.email
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard self != nil else { return }
                debugPrint("result", result)

                switch result {
                case .success(let licenseStatus):
                    self?.windyData.licenseStatus = licenseStatus
                    UserDefaults.standard.set(self?.windyData.email, forKey: "email")
                    UserDefaults.standard.set(self?.windyData.licenseKey, forKey: "licenseKey")
                    self?.lastSuccessfulVerification = Date()
                    // Unlock app if necessary
                    debugPrint("verification successful")

                case .failure(_):
                    self?.windyData.licenseStatus = "License verification failed"

                    let timeSinceLastSuccessfulVerification = Date().timeIntervalSince(self?.lastSuccessfulVerification ?? Date())
                    if timeSinceLastSuccessfulVerification > self!.gracePeriod  {
                        // Lock out app
                        debugPrint("verification unsuccessful")
                    }
                }
            }
        }
    }
}
