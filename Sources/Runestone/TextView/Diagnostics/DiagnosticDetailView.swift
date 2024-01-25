import UIKit

final class DiagnosticDetailView: UIButton, ReusableView {
    weak var diagnosticService: DiagnosticService?
    var diagnostic: Diagnostic?
    
    private let iconImageView: UIImageView = {
        let this = UIImageView()
        this.contentMode = .top
        this.translatesAutoresizingMaskIntoConstraints = false
        return this
    }()
    
    private let messageLabel: UILabel = {
        let this = UILabel()
        this.font = UIFont.systemFont(ofSize: 14)
        this.lineBreakMode = .byWordWrapping
        this.numberOfLines = 0
        this.translatesAutoresizingMaskIntoConstraints = false
        return this
    }()
    
    private let closeButton: UIButton = {
        let this = UIButton()
        this.translatesAutoresizingMaskIntoConstraints = false
        this.isExclusiveTouch = true
        this.tintColor = .darkGray
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        this.setImage(.init(systemName: "xmark.circle.fill", withConfiguration: imageConfiguration), for: .normal)
        this.contentVerticalAlignment = .top
        return this
    }()
    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        
        layer.cornerRadius = 8
        layer.cornerCurve = .continuous
        clipsToBounds = true
        isExclusiveTouch = true
        
        addSubview(iconImageView)
        addSubview(messageLabel)
        addSubview(closeButton)
        
        closeButton.addTarget(self, action: #selector(handleClose), for: .primaryActionTriggered)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            iconImageView.topAnchor.constraint(equalTo: messageLabel.topAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            closeButton.topAnchor.constraint(equalTo: messageLabel.topAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),
            messageLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -8),
            messageLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setFromDiagnostic(_ diagnostic: Diagnostic) {
        self.diagnostic = diagnostic
        
        backgroundColor = diagnostic.severity.color.withAlphaComponent(0.2)
        
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        iconImageView.image = .init(systemName: diagnostic.severity.systemImage, withConfiguration: imageConfiguration)?.withRenderingMode(.alwaysOriginal)
        
        messageLabel.attributedText = diagnostic.attributedString
    }
    
    @objc func handleClose() {
        guard let diagnosticService else { return }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.75)
        
        diagnosticService.hideDiagnostics()
    }
}
