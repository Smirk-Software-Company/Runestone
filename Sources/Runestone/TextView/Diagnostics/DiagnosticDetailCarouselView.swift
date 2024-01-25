import UIKit

final class DiagnosticDetailCarouselView: UIScrollView, ReusableView {
    weak var diagnosticService: DiagnosticService?
    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        
        isDirectionalLockEnabled = true
        contentInsetAdjustmentBehavior = .never
        isPagingEnabled = true
        showsHorizontalScrollIndicator = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setFromDiagnostics(_ diagnostics: [Diagnostic]) {
        guard let diagnosticService else { return }
        
        var oldDiagnostics: Set<Diagnostic> = .init()
        
        for subview in subviews {
            if let subview = subview as? DiagnosticDetailView {
                subview.removeFromSuperview()
                
                if let diagnostic = subview.diagnostic {
                    oldDiagnostics.insert(diagnostic)
                }
            }
        }
        
        diagnosticService.diagnosticDetailSubviewReuseQueue.enqueueViews(withKeys: oldDiagnostics)
        
        var contentWidth: CGFloat = 0
        
        contentSize = CGSize(width: frame.width * CGFloat(diagnostics.count), height: frame.height)
        
        for diagnostic in diagnostics.sorted(by: { $0.severity.rawValue < $1.severity.rawValue }) {
            let detailView = diagnosticService.diagnosticDetailSubviewReuseQueue.dequeueView(forKey: diagnostic)
            addSubview(detailView)
            detailView.diagnosticService = diagnosticService
            detailView.setFromDiagnostic(diagnostic)
            detailView.frame = CGRect(x: contentWidth, y: 0, width: frame.width, height: frame.height)
            contentWidth += frame.width
        }
    }
}
