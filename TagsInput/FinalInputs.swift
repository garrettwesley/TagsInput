//
//  FinalInput.swift
//  happen
//
//  Created by Garrett Wesley on 1/7/21.
//  Copyright © 2020 Garrett Wesley. All rights reserved.
//

import SwiftUI
import Foundation

struct SizePref: PreferenceKey {
    static var defaultValue: CGSize = .init(width: 0, height: 0)
    static func reduce(value: inout CGSize , nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct TagsOptions {
    struct TagItemOptions {
        let insets: EdgeInsets = .init(top: 6, leading: 14, bottom: 6, trailing: 14)
        let cornerRadius: CGFloat = 8
        let fontSize: CGFloat = 14
        
        let textColor: Color = .gray
        let selectedTextColor: Color = .white
        let backgroundColor: Color = .whiter
        let selectedColor: Color = .accentColor
    }
    
    let tagItemOptions: TagItemOptions = TagItemOptions()
    let tagsInsets: EdgeInsets = .init(top: 6, leading: 12, bottom: 6, trailing: 12)
    let tintColor: Color = .accentColor
    let newTagCharacter: String = " "
    let spaceBetweenTags: CGFloat = 8
    let spaceBetweenLines: CGFloat = 6
    let placeholder: String = "Add a tag"
}


public struct TagsInput: View {
    @Binding var tags: [String]
    @Binding var height: CGFloat
    
    let options: TagsOptions = TagsOptions()
    
    @State private var text: String = ""
    @State private var last: String = ""
    @State private var selection: Int? = nil
    private let minWidth: CGFloat = 60
    
    func handleInput(_ val: String) {
        selection = nil
        if val.count >= last.count {
            if val.last == " " {
                let tag = String(val[..<val.lastIndex(of: " ")!])
                if !(tags.contains(tag)) && tag.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                    $tags.wrappedValue.append(tag)
                }
                text = ""
            }
        }
        
        last = val
    }
    
    func handleDelete(index: Int) {
        selection = nil
        $tags.wrappedValue.remove(at: index)
    }
    
    /// For when TextFields can detect the backspace key
    private func didDelete() {
        if selection != nil {
            handleDelete(index: selection!)
        } else if tags.count > 0 && text.count == 0 {
            selection = tags.count - 1
        }
    }
    
    public var body: some View {
        GeometryReader { g in
            self.generateContent(with: g)
                .frame(height: height)
                .onPreferenceChange(SizePref.self, perform: { newSize in
                    $height.wrappedValue = newSize.height
                })
        }
    }
    
    private func generateContent(with g: GeometryProxy) -> some View {
        let maxWidth = g.size.width
        var currX = CGFloat.zero
        var currY = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            Group {
                ForEach(tags.indices, id: \.self) { i in
                    TagItem(active: $selection, index: i, text: tags[i], handleRemove: handleDelete, options: options.tagItemOptions)
                        .padding(.trailing, options.spaceBetweenTags)
                        .padding(.bottom, options.spaceBetweenLines)
                        .onTapGesture { selection = i }
                        .alignmentGuide(.leading, computeValue: { curr in
                            if tags[i] == self.tags.first! {
                                currX = -curr.width
                                return 0
                            }
                            
                            if (abs(currX - curr.width) > maxWidth) {
                                currX = 0
                                currY -= curr.height
                            }
                            
                            let result = currX
                            currX -= curr.width
                            
                            return result
                        })
                        .alignmentGuide(.top, computeValue: { _ in
                            if tags[i] == self.tags.first! {
                                currY = 0
                            }
                            return currY
                        })
                }
                TagsTextField(text: $text, fontSize: options.tagItemOptions.fontSize, placeholder: tags.isEmpty ? options.placeholder : "", didDelete: didDelete)
//                TextField(tags.isEmpty ? options.placeholder : "", text: $text)
                    .frame(width: calcInputWidth(g.size.width), height: calcInputHeight())
                    .onChange(of: text, perform: handleInput)
                    .padding(.trailing, options.spaceBetweenTags)
                    .padding(.bottom, options.spaceBetweenLines)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .accentColor(selection == nil ? options.tintColor : Color.clear)
                    .onTapGesture { selection = nil }
                    .alignmentGuide(.leading, computeValue: { t in
                        if (abs(currX - t.width) > maxWidth) {
                            currX = 0
                            currY -= t.height
                        }
                        let result = currX
                        currX -= t.width
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { t in
                        return tags.count > 0 ? currY : 0
                    })
            }
        }
        .anchorPreference(
            key: SizePref.self,
            value: .bounds,
            transform: { rect in
                return g[rect].size
            }
        )
    }
    
    private func calcInputHeight() -> CGFloat {
        return "TEST".size(withAttributes:[.font: UIFont.systemFont(ofSize: options.tagItemOptions.fontSize)]).height + options.tagItemOptions.insets.top + options.tagItemOptions.insets.bottom
    }
    
    private func calcInputWidth(_ maxWidth: CGFloat) -> CGFloat {
        let (lastX) = tags.reduce((CGFloat.zero)) {
            var lastX = $0
            let predictedWidth = $1.size(withAttributes:[.font: UIFont.systemFont(ofSize: options.tagItemOptions.fontSize)]).width + options.tagItemOptions.insets.leading + options.tagItemOptions.insets.trailing + options.spaceBetweenTags
            
            lastX += predictedWidth
            if lastX > maxWidth {
                lastX = predictedWidth
            }
            return lastX
        }
        
        let spaceLeft = maxWidth - lastX - (2 * options.spaceBetweenTags)
        return spaceLeft > minWidth ? spaceLeft : maxWidth - (2*options.spaceBetweenTags)
    }
}

public struct TagItem: View {
    @State private var color: Color = Color.whiter
    @Binding var active: Int?
    var opts: TagsOptions.TagItemOptions
    var index: Int
    var text: String
    var handleRemove: (Int) -> ()
    
    init(active: Binding<Int?>, index: Int, text: String, handleRemove: @escaping (Int) -> (), options: TagsOptions.TagItemOptions) {
        self._active = active
        self.text = text
        self.index = index
        self.opts = options
        self.handleRemove = handleRemove
        
        self.color = options.backgroundColor
    }
    
    public var body: some View {
        Text(text)
            .font(.system(size: opts.fontSize))
            .foregroundColor((active == index) ? opts.selectedTextColor : opts.textColor)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(opts.insets)
            .background(color)
            .cornerRadius(opts.cornerRadius)
            .onChange(of: active, perform: { val in
                withAnimation(.easeInOut(duration: 0.1)) {
                    self.color = (val == index) ? opts.selectedColor : opts.backgroundColor
                }
            })
    }
}


import UIKit

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
    var placeholder: String = ""
    var didDelete: () -> ()

    func makeUIView(context: Context) -> UITextField {
        let textField = DeleteTextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.font = .systemFont(ofSize: fontSize)
        textField.placeholder = placeholder
        textField.delegate = context.coordinator
        textField.myDelegate = context.coordinator
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text // 1. Read the binded
        uiView.placeholder = placeholder
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
                self.text = textField.text ?? ""
            }
        }
    }
}
