import UIKit

final class DiagnosticGutterView: UIView, ReusableView {
    weak var diagnosticService: DiagnosticService?
    
    private var line: DocumentLineNode?
    
    func setFromDiagnostics(_ diagnostics: [Diagnostic], for line: DocumentLineNode) {
        self.line = line
        
        let highestSeverity = diagnostics.reduce(diagnostics[0].severity, { a, b in
            if a.rawValue < b.severity.rawValue {
                return a
            }
            
            return b.severity
        })
        
        button.backgroundColor = highestSeverity.color.withAlphaComponent(0.2)
        button.tintColor = highestSeverity.color
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        button.setImage(.init(systemName: highestSeverity.systemImage, withConfiguration: imageConfiguration)?.withRenderingMode(.alwaysOriginal), for: .normal)
    }
    
    private let button: UIButton = {
        let this = UIButton()
        this.isExclusiveTouch = true
        this.layer.cornerRadius = 6
        this.layer.cornerCurve = .continuous
        this.clipsToBounds = true
        this.imageView?.contentMode = .center
        return this
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        addSubview(button)
        button.addTarget(self, action: #selector(handleTap), for: .primaryActionTriggered)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        button.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
    }
    
    @objc func handleTap() {
        guard let diagnosticService, let line else { return }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        diagnosticService.revealDiagnostics(for: line)
    }
}
