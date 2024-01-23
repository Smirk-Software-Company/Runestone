import Combine
import UIKit

final class DiagnosticGutterWidthService {
    var gutterLeadingPadding: CGFloat = 12
    var gutterTrailingPadding: CGFloat = 8
    var gutterWidth: CGFloat {
        return diagnosticWidth + gutterLeadingPadding + gutterTrailingPadding
    }
    var diagnosticWidth: CGFloat = 36
    let didUpdateGutterWidth = PassthroughSubject<Void, Never>()

    private var previouslySentGutterWidth: CGFloat?
}
