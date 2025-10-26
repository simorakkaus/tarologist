//
//  DeviceInfoService.swift
//  Tarologist
//
//  Created by Simo on 26.10.2025.
//

import SwiftUI

struct DeviceInfoService {
    
    /// Возвращает строку с информацией об устройстве
    static func getDeviceInfo() -> String {
        let device = UIDevice.current
        let systemVersion = device.systemVersion
        let deviceModel = getDeviceModel()
        let appVersion = getAppVersion()
        let currentDate = getCurrentDate()
        
        return """
        ---
        Информация об устройстве:
        Приложение: Таролог \(appVersion)
        Устройство: \(deviceModel)
        iOS: \(systemVersion)
        Дата: \(currentDate)
        """
    }
    
    /// Возвращает модель устройства
    static func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        // Сопоставление идентификаторов с читаемыми названиями
        let deviceMapping = [
            "iPhone1,1": "iPhone", "iPhone1,2": "iPhone 3G", "iPhone2,1": "iPhone 3GS",
            "iPhone3,1": "iPhone 4", "iPhone3,2": "iPhone 4", "iPhone3,3": "iPhone 4",
            "iPhone4,1": "iPhone 4S", "iPhone5,1": "iPhone 5", "iPhone5,2": "iPhone 5",
            "iPhone5,3": "iPhone 5c", "iPhone5,4": "iPhone 5c", "iPhone6,1": "iPhone 5s",
            "iPhone6,2": "iPhone 5s", "iPhone7,1": "iPhone 6 Plus", "iPhone7,2": "iPhone 6",
            "iPhone8,1": "iPhone 6s", "iPhone8,2": "iPhone 6s Plus", "iPhone8,4": "iPhone SE",
            "iPhone9,1": "iPhone 7", "iPhone9,2": "iPhone 7 Plus", "iPhone9,3": "iPhone 7",
            "iPhone9,4": "iPhone 7 Plus", "iPhone10,1": "iPhone 8", "iPhone10,2": "iPhone 8 Plus",
            "iPhone10,3": "iPhone X", "iPhone10,4": "iPhone 8", "iPhone10,5": "iPhone 8 Plus",
            "iPhone10,6": "iPhone X", "iPhone11,2": "iPhone XS", "iPhone11,4": "iPhone XS Max",
            "iPhone11,6": "iPhone XS Max", "iPhone11,8": "iPhone XR", "iPhone12,1": "iPhone 11",
            "iPhone12,3": "iPhone 11 Pro", "iPhone12,5": "iPhone 11 Pro Max", "iPhone12,8": "iPhone SE 2",
            "iPhone13,1": "iPhone 12 Mini", "iPhone13,2": "iPhone 12", "iPhone13,3": "iPhone 12 Pro",
            "iPhone13,4": "iPhone 12 Pro Max", "iPhone14,2": "iPhone 13 Pro", "iPhone14,3": "iPhone 13 Pro Max",
            "iPhone14,4": "iPhone 13 Mini", "iPhone14,5": "iPhone 13", "iPhone14,6": "iPhone SE 3",
            "iPhone14,7": "iPhone 14", "iPhone14,8": "iPhone 14 Plus", "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max", "iPhone15,4": "iPhone 15", "iPhone15,5": "iPhone 15 Plus",
            "iPhone16,1": "iPhone 15 Pro", "iPhone16,2": "iPhone 15 Pro Max",
            
            // iPad
            "iPad4,1": "iPad Air", "iPad4,2": "iPad Air", "iPad4,3": "iPad Air",
            "iPad5,3": "iPad Air 2", "iPad5,4": "iPad Air 2", "iPad6,7": "iPad Pro 12.9\"",
            "iPad6,8": "iPad Pro 12.9\"", "iPad6,3": "iPad Pro 9.7\"", "iPad6,4": "iPad Pro 9.7\"",
            "iPad7,1": "iPad Pro 12.9\" 2gen", "iPad7,2": "iPad Pro 12.9\" 2gen",
            "iPad7,3": "iPad Pro 10.5\"", "iPad7,4": "iPad Pro 10.5\"",
            
            // Simulator
            "x86_64": "Simulator", "arm64": "Simulator"
        ]
        
        return deviceMapping[identifier] ?? identifier
    }
    
    /// Возвращает версию приложения
    static func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
    
    /// Возвращает текущую дату в формате строки
    static func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: Date())
    }
}
