//
//  TagsInput.swift
//  TagsInput
//
//  Created by Garrett Wesley on 1/5/21.
//

import SwiftUI

struct SizePref: PreferenceKey {
    static var defaultValue: CGSize = .init(width: 0, height: 0)
    static func reduce(value: inout CGSize , nextValue: () -> CGSize) {
        value = nextValue()
    }
}

public struct NewTagsInput: View {
    @State private var height: CGFloat = 0
    
    /// Pass through params
    @Binding var tags: [String]
    var options: TagsOptions = TagsOptions()
    
    public var body: some View {
//        GeometryReader { p in
            OldTagsController(tags: $tags, options: options)
//                .anchorPreference(
//                    key: SizePref.self,
//                    value: .bounds,
//                    transform: {
//                        p[$0].size
//                    }
//                )
//                .frame(height: height)
//                .onPreferenceChange(SizePref.self, perform: { newSize in
//                    self.height = newSize.height
//                    print(self.height)
//                })
//        }
    }
}


public struct OldTagsController: View {
    struct SizePreferenceKey: PreferenceKey {
        typealias Value = [CGSize]
        static var defaultValue: Value = []
        static func reduce(value: inout Value, nextValue: () -> Value) {
            value.append(contentsOf: nextValue())
        }
    }
    
    @Binding var tags: [String]
    var options: TagsOptions = TagsOptions()

    @State private var height: CGFloat = 0
    @State private var sizes: [CGSize] = []
    @State private var text: String = ""
    @State private var last: String = ""
    @State private var selection: Int? = nil
    private let minWidth: CGFloat = 80
    
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
    
    /// To be used when TextFields can detect the backspace key
    private func didDelete() {
        if selection != nil {
            handleDelete(index: selection!)
        } else if tags.count > 0 && text.count == 0 {
            selection = tags.count - 1
        }
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Group {
                    ForEach(tags.indices, id: \.self) { i in
                        TagItem(active: $selection, index: i, text: tags[i], handleRemove: handleDelete, options: options.tagItemOptions)
                            .padding(.trailing, options.spaceBetweenTags)
                            .padding(.bottom, options.spaceBetweenLines)
                            .onTapGesture { selection = i }
                            .background(backgroundView())
                            .offset(getOffset(at: i, geometry: geometry))
                    }
                    TextField(tags.isEmpty ? options.placeholder : "", text: $text)
                        .frame(width: getWidth(from: geometry), height: 30)
                        .onChange(of: text, perform: handleInput)
                        .padding(.leading, options.spaceBetweenTags)
                        .padding(.bottom, options.spaceBetweenLines)
                        .background(Color.gray)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .accentColor(selection == nil ? Color.blue : Color.clear)
                        .onTapGesture { selection = nil }
                        .background(backgroundView())
                        .offset(getInputOffset(geometry))
                }
                .anchorPreference(
                    key: SizePref.self,
                    value: .bounds,
                    transform: {
                        geometry[$0].size
                    }
                )
            }
            .frame(width: geometry.size.width, height: height)
        }
        .onPreferenceChange(SizePref.self, perform: { newSize in
            self.height = newSize.height
            print("New height =",self.height)
        })
        .onPreferenceChange(SizePreferenceKey.self) {
            self.sizes = $0
        }
    }
    
    private func getWidth(from g: GeometryProxy) -> CGFloat {
        guard tags.count > 0 && sizes.count > 0 else { return g.size.width }

        let w = g.size.width
        let (lastX, _, _) = sizes[..<(sizes.count - 1)].reduce((CGFloat.zero,CGFloat.zero,CGFloat.zero)) {
            var (x,y,maxHeight) = $0
            x += $1.width
            if x > w {
                x = $1.width
                y += maxHeight
                maxHeight = 0
            }
            maxHeight = max(maxHeight, $1.height)
            return (x,y,maxHeight)
        }
        
        let spaceLeft = w - lastX - 15
        return spaceLeft > minWidth ? spaceLeft : w
    }
    
    private func getInputOffset(_ g: GeometryProxy) -> CGSize {
        guard sizes.count > 0 else { return .zero }
        return getOffset(at: sizes.endIndex - 1, geometry: g)
    }
    
    private func getOffset(at index: Int, geometry: GeometryProxy) -> CGSize {
        guard index < sizes.endIndex else { return .zero }
        let frame = sizes[index]
        var (x, y, maxHeight) = sizes[..<index].reduce((CGFloat.zero,CGFloat.zero,CGFloat.zero)) {
            var (x, y, maxHeight) = $0
            x += $1.width
            if x > geometry.size.width {
                x = $1.width
                y += maxHeight
                maxHeight = 0
            }
            maxHeight = max(maxHeight, $1.height)
            return (x,y,maxHeight)
        }
        if x + frame.width > geometry.size.width {
            x = 0
            y += maxHeight
        }
        return .init(width: x, height: y)
    }
    
    private func backgroundView() -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.clear)
                .preference(
                    key: SizePreferenceKey.self,
                    value: [geometry.frame(in: CoordinateSpace.global).size]
                )
        }
    }
}
