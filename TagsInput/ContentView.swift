//
//  TagsInput.swift
//  TagsInput
//
//  Created by Garrett Wesley on 1/5/21.
//
 
import SwiftUI
import Foundation
 
struct TagsInput: View {
    @State var tags: [String] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                TagsController(tags: $tags, maxWidth: geometry.size.width - 24, addTag: addTag, removeTag: removeTag, shouldAddTag: shouldAddTag)
            }
            .padding(.horizontal, 20)
        }
    }
    
    func addTag(_ val: String) {
        tags.append(val)
    }
    
    func removeTag(_ i: Int) {
        tags.remove(at: i)
    }
    
    func shouldAddTag(_ tag: String, _ tags: [String]) -> Bool {
        return !(tags.contains(tag))
    }
 }
 
 struct TagsOptions {
    struct TagItemOptions {
        let insets: EdgeInsets = .init(top: 6, leading: 14, bottom: 6, trailing: 14)
        let cornerRadius: CGFloat = 8
        let fontSize: CGFloat = 14
        
        let textColor: Color = .white
        let selectedTextColor: Color = .white
        let backgroundColor: Color = .gray
        let selectedColor: Color = .red
    }
    
    let tagItemOptions: TagItemOptions = TagItemOptions()
    let tagsInsets: EdgeInsets = .init(top: 6, leading: 12, bottom: 6, trailing: 12)
    let tintColor: Color = Color(UIColor.blue)
    let newTagCharacter: String = " "
    let spaceBetweenTags: CGFloat = 6
    let spaceBetweenLines: CGFloat = 6
    let placeholder: String = "Add a tag"
 }
 
 public struct TagsController: View {
    struct SizePreferenceKey: PreferenceKey {
        typealias Value = [CGSize]
        static var defaultValue: Value = []
        static func reduce(value: inout Value, nextValue: () -> Value) {
            value.append(contentsOf: nextValue())
        }
    }
    
    @Binding var tags: [String]
    let maxWidth: CGFloat
    let addTag: (String) -> ()
    let removeTag: (Int) -> ()
    let shouldAddTag: (String, [String]) -> (Bool)
    let options: TagsOptions
    
    @State private var sizes: [CGSize] = []
    @State private var text: String = ""
    @State private var last: String = ""
    @State private var selection: Int? = nil
    private let minWidth: CGFloat = 60
    
    init(tags: Binding<[String]>, maxWidth: CGFloat, addTag: @escaping (String) -> (), removeTag: @escaping (Int) -> (), shouldAddTag: @escaping (String, [String]) -> (Bool), options: TagsOptions = TagsOptions()) {
        self._tags = tags
        self.addTag = addTag
        self.removeTag = removeTag
        self.shouldAddTag = shouldAddTag
        self.maxWidth = maxWidth - options.tagsInsets.trailing - options.tagsInsets.leading
        self.options = options
        
    }
    
    func handleInput(_ val: String) {
        selection = nil
        if val.count >= last.count {
            if val.last == " " {
                let tag = String(val[..<val.lastIndex(of: " ")!])
                if shouldAddTag(tag, tags) && tag.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                    addTag(tag)
                }
                text = ""
            }
        }
        
        last = val
    }
    
    func handleDelete(index: Int) {
        selection = nil
        removeTag(index)
    }
    
    /// For when TextFields can detect the backspace key
    private func didDelete() {
        if selection != nil {
            removeTag(selection!)
            selection = nil
        } else if tags.count > 0 && text.count == 0 {
            selection = tags.count - 1
        }
    }
    
    public var body: some View {
        self.generateContent()
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black, lineWidth: 2)
            )
    }
    
    private func generateContent() -> some View {
        var currX = CGFloat.zero
        var currY = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
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
//            TagsTextField(text: $text, fontSize: options.tagItemOptions.fontSize, didDelete: didDelete)
            TextField(tags.isEmpty ? options.placeholder : "", text: $text)
                .frame(width: calcInputWidth(), height: options.tagItemOptions.fontSize + options.tagItemOptions.insets.top + options.tagItemOptions.insets.bottom, alignment: .bottom)
                .onChange(of: text, perform: handleInput)
                .padding(.leading, options.spaceBetweenTags)
                .padding(.bottom, options.spaceBetweenLines)
                .background(Color.gray)
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .accentColor(selection == nil ? Color.blue : Color.clear)
                .onTapGesture { selection = nil }
                .alignmentGuide(.leading, computeValue: { t in
                    print(maxWidth, "curr size:", t.width)
                    if (abs(currX - t.width) > maxWidth) {
                        currX = 0
                        currY -= t.height
                    }
                    let result = currX
                    currX -= t.width
//                    print(result)
                    return result
                })
                .alignmentGuide(.top, computeValue: { t in
                    return tags.count > 0 ? currY : 0
                })
        }
        .frame(width: maxWidth)
    }
    
    private func calcInputWidth() -> CGFloat {
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
        let res = spaceLeft > minWidth ? spaceLeft : maxWidth - (2*options.spaceBetweenTags)
        print("keyboard width: ", res)
        return res
    }
}
 
public struct TagItem: View {
    @State private var color: Color = Color.gray
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
        ZStack(alignment: .center) {
            Text(text)
                .font(.system(size: opts.fontSize))
                .foregroundColor((active == index) ? opts.selectedTextColor : opts.textColor)
                .lineLimit(1)
                .truncationMode(.tail)
                .opacity((active == index) ? 0 : 1)
            if active == index {
                Button(action: { handleRemove(index) }) {
                    Image(systemName: "x.circle")
                        .font(.system(size: opts.fontSize))
                        .foregroundColor(opts.selectedTextColor)
                }
                .opacity((active == index) ? 1 : 0)
            }
            
        }
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
