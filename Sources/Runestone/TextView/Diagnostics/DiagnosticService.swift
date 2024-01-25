import UIKit

final class DiagnosticService {
    weak var layoutManager: LayoutManager?
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
    private var innerPadding: CGFloat = 20
    var verticalPadding: CGFloat = 8
    
    private var diagnosticsDetailMessageHeight: CGFloat = 0
    
    private var revealedDiagnosticsLine: DocumentLineNode? {
        didSet {
            if revealedDiagnosticsLine != oldValue {
                if let revealedDiagnosticsLine {
                    measureDiagnosticsDetailHeight()
                } else {
                    diagnosticsDetailMessageHeight = 0
                }
            }
        }
    }
    
    private var diagnosticsPerLine: [DocumentLineNodeID: [Diagnostic]] = [:]
    
    var diagnosticDetailSubviewReuseQueue = ViewReuseQueue<Diagnostic, DiagnosticDetailView>()
    
    init(lineManager: LineManager) {
        self.lineManager = lineManager
    }
    
    func diagnostics(for line: DocumentLineNode) -> [Diagnostic] {
        return diagnosticsPerLine[line.id] ?? []
    }
    
    func diagnosticsRevealed(for line: DocumentLineNode) -> Bool {
        return revealedDiagnosticsLine == line
    }
    
    private let measureLabel: UILabel = {
        let this = UILabel()
        this.font = UIFont.systemFont(ofSize: 14)
        this.lineBreakMode = .byWordWrapping
        this.numberOfLines = 0
        return this
    }()
    
    private func measureDiagnosticsDetailHeight() {
        guard let layoutManager, let revealedDiagnosticsLine else { return }
        
        let diagnosticDetailFrame = CGRect(x: 0, y: 0, width: layoutManager.insetWidth - 76, height: .greatestFiniteMagnitude)
        
        var maxHeight: CGFloat = 0
        
        for diagnostic in diagnostics(for: revealedDiagnosticsLine) {
            measureLabel.attributedText = diagnostic.attributedString
            
            let rect = measureLabel.textRect(forBounds: diagnosticDetailFrame, limitedToNumberOfLines: 0)
            
            maxHeight = max(maxHeight, rect.height)
        }
        
        diagnosticsDetailMessageHeight = maxHeight
    }
    
    func diagnosticsDetailHeight(for line: DocumentLineNode) -> CGFloat {
        guard let revealedDiagnosticsLine, line == revealedDiagnosticsLine else { return 0 }
        
        return diagnosticsDetailMessageHeight + innerPadding
    }
    
    func totalDiagnosticsDetailHeight(for line: DocumentLineNode) -> CGFloat {
        guard let revealedDiagnosticsLine, line == revealedDiagnosticsLine else { return 0 }
        
        return diagnosticsDetailMessageHeight + innerPadding + (verticalPadding * 2)
    }
    
    func hideDiagnostics() {
        guard revealedDiagnosticsLine != nil else { return }
        
        revealedDiagnosticsLine = nil
        
        layoutManager?.setNeedsLayout()
        layoutManager?.layoutIfNeeded()
    }
    
    func revealDiagnostics(for line: DocumentLineNode) {
        guard revealedDiagnosticsLine != line else { return }
        
        revealedDiagnosticsLine = line
        
        layoutManager?.setNeedsLayout()
        layoutManager?.layoutIfNeeded()
    }
}

private extension DiagnosticService {
    private func invalidateDiagnostics() {
        diagnosticsPerLine.removeAll()
        diagnosticsPerLine = createDiagnosticsPerLine()
        
        if let revealedDiagnosticsLine {
            if diagnostics(for: revealedDiagnosticsLine).isEmpty {
                hideDiagnostics()
            } else {
                measureDiagnosticsDetailHeight()
            }
        }
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
