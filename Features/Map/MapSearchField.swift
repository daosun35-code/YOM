import SwiftUI
import UIKit

struct NativeSearchTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFirstResponder: Bool
    let placeholder: String
    let accessibilityLabel: String
    let accessibilityIdentifier: String
    let onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            onSubmit: onSubmit
        )
    }

    func makeUIView(context: Context) -> DeferredFirstResponderTextField {
        let textField = DeferredFirstResponderTextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange(_:)),
            for: .editingChanged
        )
        textField.returnKeyType = .search
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.clearButtonMode = .never
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.textColor = .label
        textField.tintColor = .label
        textField.accessibilityTraits.insert(.searchField)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textField
    }

    func updateUIView(_ uiView: DeferredFirstResponderTextField, context: Context) {
        context.coordinator.text = $text
        context.coordinator.onSubmit = onSubmit

        if uiView.text != text {
            uiView.text = text
        }
        if uiView.placeholder != placeholder {
            uiView.placeholder = placeholder
        }
        uiView.accessibilityLabel = accessibilityLabel
        uiView.accessibilityIdentifier = accessibilityIdentifier
        uiView.desiredFirstResponder = isFirstResponder
        uiView.reconcileFirstResponder()
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        var onSubmit: () -> Void

        init(
            text: Binding<String>,
            onSubmit: @escaping () -> Void
        ) {
            self.text = text
            self.onSubmit = onSubmit
        }

        @objc func textDidChange(_ textField: UITextField) {
            text.wrappedValue = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            onSubmit()
            return true
        }
    }
}

final class DeferredFirstResponderTextField: UITextField {
    var desiredFirstResponder = false
    private var hasPendingFirstResponderRequest = false

    override func willMove(toWindow newWindow: UIWindow?) {
        if newWindow == nil, isFirstResponder {
            resignFirstResponder()
        }
        super.willMove(toWindow: newWindow)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        reconcileFirstResponder()
    }

    func reconcileFirstResponder() {
        guard desiredFirstResponder else {
            hasPendingFirstResponderRequest = false
            if isFirstResponder {
                resignFirstResponder()
            }
            return
        }

        guard window != nil else { return }
        guard isFirstResponder == false else {
            hasPendingFirstResponderRequest = false
            return
        }
        guard hasPendingFirstResponderRequest == false else { return }

        hasPendingFirstResponderRequest = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.hasPendingFirstResponderRequest = false
            guard self.desiredFirstResponder else { return }
            guard self.window != nil else { return }
            guard self.isFirstResponder == false else { return }
            _ = self.becomeFirstResponder()
        }
    }
}
