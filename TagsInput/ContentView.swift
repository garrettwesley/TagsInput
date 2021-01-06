//
//  ContentView.swift
//  TagsInput
//
//  Created by Garrett Wesley on 1/5/21.
//

import SwiftUI

struct TagsInput: View {
    @State var tags: [String] = ["test"]
    @State var test = ""
    
    var body: some View {
        VStack {
            TagsController(tags: $tags, addTag: addTag, removeTag: removeTag)
        }
    }
        
    func addTag(_ val: String) {
        tags.append(val)
    }
    
    func removeTag(_ i: Int) {
        tags.remove(at: i)
    }
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
    var addTag: (String) -> ()
    var removeTag: (Int) -> ()
    
    @State private var sizes: [CGSize] = []
    @State private var text: String = ""
    @State private var last: String = ""
    @State private var selection: Int? = nil
    private let minWidth: CGFloat = 80
    
    func handleInput(_ val: String) {
        selection = nil
        if val.count >= last.count {
            if val.last == " " {
                let str = String(val[..<val.lastIndex(of: " ")!])
                if !(tags.contains(str)) && str.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                    addTag(str)
                }
                text = ""
            }
        }
        
        last = val
    }
    
    func didDelete() {
        if selection != nil {
            removeTag(selection!)
            selection = nil
        } else if tags.count > 0 {
            selection = tags.count - 1
        }
    }
    
    public var body: some View {
        GeometryReader {geometry in
            ZStack(alignment: .topLeading) {
                ForEach(tags.indices, id: \.self) { i in
                    Group {
                        TagItem(active: $selection, index: i, text: tags[i])
                    }
                    .onTapGesture {
                        selection = i
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
                    .background(backgroundView())
                    .offset(getOffset(at: i, geometry: geometry))
                }
                TagsTextField(text: $text, didDelete: didDelete)
                    .frame(width: getWidth(from: geometry), height: 30)
                    .onChange(of: text, perform: handleInput)
                    .padding(.leading, 8)
                    .padding(.bottom, 4)
                    .background(backgroundView())
                    .offset(getInputOffset(geometry))
                    .accentColor(selection == nil ? Color.blue : Color.clear)
                    .onTapGesture {
                        selection = nil
                    }
            }
        }.onPreferenceChange(SizePreferenceKey.self) {
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

public struct TagItem: View {
    @State private var color: Color = Color.gray
    @Binding var active: Int?
    var index: Int
    var text: String
    
    public var body: some View {
        Text(text)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .font(.system(size: 14))
            .background(color)
            .foregroundColor(Color.white)
            .cornerRadius(8)
            .lineLimit(1)
            .truncationMode(.tail)
            .onChange(of: active, perform: { val in
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.color = val == index ? .red : .gray
                }
            })
    }
}
