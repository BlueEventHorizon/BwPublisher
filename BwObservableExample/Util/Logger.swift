//
//  Logger.swift
//  BwFramework
//
//  Created by Katsuhiko Terada on 2017/08/18.
//  Copyright (c) 2017 Katsuhiko Terada. All rights reserved.
//

import UIKit // For CGPoint

// =============================================================================
// MARK: - LoggerOutput
// =============================================================================

public protocol LoggerOutput {
    func log(_ formedMessage: String, original: String, level: Logger.Level)
}

private final class DefaultLoggerOutput: LoggerOutput {
    public func log(_ formedMessage: String, original: String, level: Logger.Level) {
        print(formedMessage)
    }
}

// =============================================================================
// MARK: - LoggerControllable
// =============================================================================

public protocol LoggerControllable {
    func isEnabled(_ level: Logger.Level) -> Bool
}

private final class DefaultLoggerController: LoggerControllable {
    public func isEnabled(_ level: Logger.Level) -> Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

// =============================================================================
// MARK: - Logger
// =============================================================================

/// You can make another instances in your own files
/// And choose level for output by each instances with levels parameter
public let logger = Logger(levels: nil)

public final class Logger
{
    /// Injectable for output target.
    public var output: LoggerOutput = DefaultLoggerOutput()
    /// Injectable for output level.
    public var controller: LoggerControllable = DefaultLoggerController()

    private var levels: [Level]?

    public init() {}
    public init(levels: [Level]? = nil) {
        self.levels = levels
    }

    /// Format message and other metrics for log output.
    ///
    /// - Parameters:
    ///   - message: your main message
    ///   - postMessage: your message behind other metrics
    ///   - shifter: log starting position shifter by space
    ///   - level: log level
    ///   - instance: instance which has sent this log/message
    ///   - function: function name
    ///   - file: fine name
    ///   - line: line number
    /// - Returns: formatted strings for log
    private func formatter(_ message: String, postMessage: String = "", shifter: Int = 0, level: Level, instance: Any, function: String, file: String, line: Int) -> String {
        var shifterString: String = ""
        if shifter > 0 {
            shifterString = String(repeating: " ", count: shifter)
        }

        // Log Thread
        var threadName: String = "main"
        if !Thread.isMainThread {
            if let _threadName = Thread.current.name, !_threadName.isEmpty {
                threadName = _threadName
            } else if let _queueName = String(validatingUTF8: __dispatch_queue_get_label(nil)), !_queueName.isEmpty {
                threadName = _queueName
            } else {
                threadName = Thread.current.description
            }
        }

        // Log Date
        var result: String = "\(shifterString)\(level.presentation()) [\(Date().string(dateFormat: "yyyy-MM-dd HH:mm:ss"))]"
        if level.isEnabledThread() {
            result += " [\(threadName)]"
        }
        var sep1 = ""

        // Log File
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        var classNameLocal: String = ""

        // Log Message
        if !message.isEmpty {
            result += " \(message)"
            sep1 = " __"
        }

        // Log Class/Function
        if level.isEnabledFunctionName() {
            if let identifierGettableObject = instance as? Identifiable {
                classNameLocal = identifierGettableObject.identifier
            } else if let stringObject = instance as? String {
                if stringObject.hasSuffix(".swift") {
                    // remove ".swift" from file name
                    let path: [String] = stringObject.components(separatedBy: "/")
                    if let last = path.last {
                        let a: [String] = last.components(separatedBy: ".")
                        if let b = a.first {
                            classNameLocal = b
                        }
                    }
                } else {
                    classNameLocal = stringObject
                }
            }

            if classNameLocal.isEmpty {
                result += "\(sep1) \(function)"
            } else {
                result += "\(sep1) \(classNameLocal):\(function)"
            }
        }

        // Post Message
        if !postMessage.isEmpty {
            result += " __" + " \(postMessage)"
        }

        // File/Line Information
        if level.isEnabledLineNumber() {
            result += " \(fileName):\(line)"
        }

        return result
    }

    // =============================================================================
    // MARK: - API
    // =============================================================================

    /// Output log
    ///
    /// - Parameters:
    ///   - original: original message
    ///   - postMessage: sub message added after
    ///   - shifter: if function is nested, tihs log will be shifted by this count
    ///   - level: log level
    ///   - instance: if you don't add instance object, file name will be used, but if you add instance object that has Identifiable protocol, you can see class name instead of file name.
    ///   - function: automatically added function name
    ///   - file: automatically added file name
    ///   - line: automatically added line number
    static private let semaphore  = DispatchSemaphore(value: 1)
    private func log(_ original: String, postMessage: String = "", shifter: Int = 0, level: Level, instance: Any, function: String, file: String, line: Int) {
        Logger.semaphore.wait()
        defer {
            Logger.semaphore.signal()
        }

        guard controller.isEnabled(level) else { return }
        guard levels?.contains(level) ?? false || levels == nil else { return }

        let formedMessage = formatter(original, postMessage: postMessage, shifter: shifter, level: level, instance: instance, function: function, file: file, line: line)
        self.output.log(formedMessage, original: original, level: level)

        if level == .fatal {
            assert(false, formedMessage)
        }
    }
}

// =============================================================================
// MARK: - Logger.Level
// =============================================================================

public extension Logger {
    enum Level: String, CaseIterable {
        case enter      // enter into method
        case exit       // exit from method
        case screen     // screen appeared
        case debug      // for debug
        case info       // for generic information
        case warn       // for warning
        case error      // for error
        case fatal      // for fatal error (assert)

        public func presentation() -> String {
            switch self {
            case .enter:    return "========>"
            case .exit:     return "<========"
            case .screen:   return "[⏩SCREN]"
            case .debug:    return "[🔸DEBUG]"
            case .info:     return "[🔹INFO ]"
            case .warn:     return "[⚠️WARN ]"
            case .error:    return "[❌ERROR]"
            case .fatal:    return "[❌FATAL]"
            }
        }

        // true: Add file name and line number at the end of log
        fileprivate func isEnabledLineNumber() -> Bool {
            switch self {
            case .enter:    return false
            case .exit:     return false
            case .info:     return false
            default:        return true
            }
        }

        fileprivate func isEnabledThread() -> Bool {
            switch self {
            case .info:     return false
            default:        return true
            }
        }

        fileprivate func isEnabledFunctionName() -> Bool {
            switch self {
            case .info, .screen:    return false
            default:                return true
            }
        }
    }
}

// =============================================================================
// MARK: - extension
// =============================================================================

public extension Logger {
    /// Method Entered Log
    ///
    /// - Parameters:
    ///   - instance: if you don't add instance object, file name will be used, but if you add instance object that has Identifiable protocol, you can see class name instead of file name.
    ///   - message: sub message
    ///   - shifter: if function is nested, tihs log will be shifted by this count
    ///   - function: automatically added function name
    ///   - file: automatically added file name
    ///   - line: automatically added line number
    func entered(_ instance: Any = #file, message: String = "", shifter: Int = 0, function: String = #function, file: String = #file, line: Int = #line) {
        self.log("", postMessage: message, shifter: shifter, level: .enter, instance: instance, function: function, file: file, line: line)
    }

    // Method Exit Log
    func exit(_ instance: Any = #file, message: String = "", shifter: Int = 0, function: String = #function, file: String = #file, line: Int = #line) {
        self.log("", postMessage: message, shifter: shifter, level: .exit, instance: instance, function: function, file: file, line: line)
    }

    func screen(_ message: String, instance: Any = #file, function: String = #function, file: String = #file, line: Int = #line) {
        self.log(message, level: .screen, instance: instance, function: function, file: file, line: line)
    }

    func debug(_ message: String, instance: Any = #file, function: String = #function, file: String = #file, line: Int = #line) {
        self.log(message, level: .debug, instance: instance, function: function, file: file, line: line)
    }

    func info(_ message: String, instance: Any = #file, function: String = #function, file: String = #file, line: Int = #line) {
        self.log(message, level: .info, instance: instance, function: function, file: file, line: line)
    }

    func warn(_ message: String, instance: Any = #file, function: String = #function, file: String = #file, line: Int = #line) {
        self.log(message, level: .warn, instance: instance, function: function, file: file, line: line)
    }

    func error(_ message: String, instance: Any = #file, function: String = #function, file: String = #file, line: Int = #line) {
        self.log(message, level: .error, instance: instance, function: function, file: file, line: line)
    }

    func fatal(_ message: String, instance: Any = #file, function: String = #function, file: String = #file, line: Int = #line) {
        self.log(message, level: .fatal, instance: instance, function: function, file: file, line: line)
    }
}

// =============================================================================
// MARK: - extension
// =============================================================================

public extension Logger {
    func pointString(_ point: CGPoint) -> String {
        return "x=" + String(describing: point.x) + ", y=" + String(describing: point.y)
    }

    func point(_ point: CGPoint, message: String = "", instance: Any = #file, function: String = #function, file: String = #file, line: Int = #line) {
        let msg = "\(pointString(point)) \(message)"
        self.log(msg, level: .info, instance: instance, function: function, file: file, line: line)
    }

    func frameString(_ frame: CGRect) -> String {
        return "x= \(String(describing: frame.origin.x)), y= \(String(describing: frame.origin.y)), w= \(String(describing: frame.size.width)), h= \(String(describing: frame.size.height))"
    }

    func frame(_ frame: CGRect, message: String = "", instance: Any = #file, function: String = #function, file: String = #file, line: Int = #line) {
        let msg = "\(frameString(frame)) \(message)"
        self.log(msg, level: .info, instance: instance, function: function, file: file, line: line)
    }

    func url(_ url: URL) {
        self.info("url : \(url.absoluteString)")

        if let _scheme = url.scheme {
            self.info("scheme : \(_scheme)")
        }
        if let _host = url.host {
            self.info("host : \(_host)")
        }
        if let _port = url.port {
            self.info("port : \(_port)")
        }
        if let _query = url.query {
            self.info("query : \(_query)")
        }
    }
}
