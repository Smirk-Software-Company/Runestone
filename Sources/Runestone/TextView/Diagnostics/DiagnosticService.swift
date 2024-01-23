import Foundation

final class DiagnosticService {
    var lineManager: LineManager {
        didSet {
            if lineManager !== oldValue {
                invalidateDiagnostics()
            }
        }
    }
    var diagnostics: [Diagnostic] = [] {
        didSet {
            if diagnostics != oldValue {
                invalidateDiagnostics()
            }
        }
    }
    
    private var diagnosticsPerLine: [DocumentLineNodeID: [Diagnostic]] = [:]
    
    init(lineManager: LineManager) {
        self.lineManager = lineManager
    }
    
    func diagnostics(for line: DocumentLineNode) -> [Diagnostic] {
        return diagnosticsPerLine[line.id] ?? []
    }
}

private extension DiagnosticService {
    private func invalidateDiagnostics() {
        diagnosticsPerLine.removeAll()
        diagnosticsPerLine = createDiagnosticsPerLine()
    }
    
    private func createDiagnosticsPerLine() -> [DocumentLineNodeID: [Diagnostic]] {
        var result: [DocumentLineNodeID: [Diagnostic]] = [:]
        for diagnostic in diagnostics {
            let lines = lineManager.lines(in: diagnostic.range)
            for line in lines {
                let lineRange = NSRange(location: line.location, length: line.data.totalLength)
                guard diagnostic.range.overlaps(lineRange) else { continue }
                let cappedRange = diagnostic.range.capped(to: lineRange)
                let cappedLocalRange = cappedRange.local(to: lineRange)
                let diagnosticItem = Diagnostic(range: cappedLocalRange, severity: diagnostic.severity, message: diagnostic.message)
                if let existingDiagnostics = result[line.id] {
                    result[line.id] = existingDiagnostics + [diagnosticItem]
                } else {
                    result[line.id] = [diagnosticItem]
                }
            }
        }
        return result
    }
}
