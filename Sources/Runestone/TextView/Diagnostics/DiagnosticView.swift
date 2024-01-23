import UIKit

final class DiagnosticView: UIView, ReusableView {
    func setFromDiagnostics(_ diagnostics: [Diagnostic]) {
        let highestSeverity = diagnostics.reduce(diagnostics[0].severity, { a, b in
            if a.rawValue < b.severity.rawValue {
                return a
            }
            
            return b.severity
        })
        
        button.backgroundColor = highestSeverity.color.withAlphaComponent(0.2)
        button.tintColor = highestSeverity.color
        button.setImage(.init(systemName: highestSeverity.systemImage, withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)), for: .normal)
    }
    
    private let button: UIButton = {
        let this = UIButton()
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
        print("tapped!!")
    }
}
