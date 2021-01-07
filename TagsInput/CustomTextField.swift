//
//  CustomTextField.swift
//  TagsInput
//
//  Created by Garrett Wesley on 1/5/21.
//

import UIKit
import SwiftUI

protocol DeleteTextFieldDelegate: AnyObject {
    func textFieldDidDelete()
}

class DeleteTextField: UITextField {

    weak var myDelegate: DeleteTextFieldDelegate?

    override func deleteBackward() {
        super.deleteBackward()
        myDelegate?.textFieldDidDelete()
    }

}

struct TagsTextField: UIViewRepresentable {
    @Binding var text: String
    var fontSize: CGFloat
    var didDelete: () -> ()

    func makeUIView(context: Context) -> UITextField {
        let textField = DeleteTextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.font = .systemFont(ofSize: fontSize)
        textField.delegate = context.coordinator
        textField.myDelegate = context.coordinator
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text // 1. Read the binded
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, didDelete: didDelete)
    }

    class Coordinator: NSObject, UITextFieldDelegate, DeleteTextFieldDelegate {
        @Binding var text: String
        var didDelete: () -> ()

        init(text: Binding<String>, didDelete: @escaping () -> ()) {
            self._text = text
            self.didDelete = didDelete
        }
        
        func textFieldDidDelete() {
            didDelete()
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.text = textField.text ?? "" // 2. Write to the binded
            }
        }
    }
}
