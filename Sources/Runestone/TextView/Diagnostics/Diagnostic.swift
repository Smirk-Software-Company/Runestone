import UIKit

public struct Diagnostic: Hashable {
    public let id: String
    public let range: NSRange
    public let severity: Severity
    public let message: String
    
    public init(range: NSRange, severity: Severity, message: String) {
        self.id = UUID().uuidString
        self.range = range
        self.severity = severity
        self.message = message
    }
    
    var color: UIColor {
        return severity.color
    }
    
    var attributedString: NSAttributedString {
        if #available(iOS 15, *) {
            if let str = try? NSAttributedString(markdown: message) {
                return str
            }
        }
        
        return NSAttributedString(string: message)
    }
}

extension Diagnostic {
    public enum Severity: Int, Equatable, Hashable {
        case error = 1
        case warning = 2
        case information = 3
        case hint = 4
        
        var color: UIColor {
            switch self {
            case .error:
                return .red
            case .warning:
                return .yellow
            case .information:
                return .gray
            case .hint:
                return .gray
            }
        }
        
        var systemImage: String {
            switch self {
            case .error:
                return "xmark.circle.fill"
            case .warning:
                return "exclamationmark.triangle.fill"
            case .information:
                return "info.circle.fill"
            case .hint:
                return "info.circle.fill"
            }
        }
    }
}

extension Diagnostic: Equatable {
    public static func == (lhs: Diagnostic, rhs: Diagnostic) -> Bool {
        lhs.id == rhs.id && lhs.range == rhs.range && lhs.severity == rhs.severity && lhs.message == rhs.message
    }
}
