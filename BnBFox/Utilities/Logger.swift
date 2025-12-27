//
//  Logger.swift
//  BnBShift
//
//  Created for App Store production readiness
//  Conditional debug logging - automatically disabled in Release builds
//

import Foundation

struct Logger {
    /// Log a debug message - only prints in DEBUG builds
    static func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent
        print("[\(filename):\(line)] \(function) - \(message)")
        #endif
    }
    
    /// Log an error message - prints in all builds
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        print("❌ ERROR [\(filename):\(line)] \(function) - \(message)")
    }
    
    /// Log a warning message - only prints in DEBUG builds
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent
        print("⚠️  WARNING [\(filename):\(line)] \(function) - \(message)")
        #endif
    }
    
    /// Log an info message - only prints in DEBUG builds
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent
        print("ℹ️  INFO [\(filename):\(line)] \(function) - \(message)")
        #endif
    }
}

