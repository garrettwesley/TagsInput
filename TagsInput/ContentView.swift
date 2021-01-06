//
//  ContentView.swift
//  TagsInput
//
//  Created by Garrett Wesley on 1/5/21.
//

import SwiftUI

struct TagsInput: View {
    @State var tags: [String] = ["test"]
    
    var body: some View {
        TagsController(tags: $tags, addTag: addTag, removeTag: removeTag)
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
        if val.count >= last.count {
            if val.last == " " {
//                String.Index
                let str = String(val[..<val.lastIndex(of: " ")!])
                if !(tags.contains(str)) {
                    addTag(str)
                }
                text = ""
            }
        }
        
        last = val
    }
    
    public var body: some View {
        GeometryReader {geometry in
            ZStack(alignment: .topLeading) {
                ForEach(tags.indices, id: \.self) { i in
                    Group {
                        Text(tags[i])
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .font(.body)
                            .background(selection == i ? Color.red : Color.gray)
                            .foregroundColor(Color.white)
                            .cornerRadius(8)
                    }
                    .onTapGesture {
                        selection = i
                    }
                    .padding(.leading, 8)
                    .padding(.bottom, 4)
                    .background(backgroundView())
                    .offset(getOffset(at: i, geometry: geometry))
                }
                TextField("", text: $text)
                    .frame(width: getWidth(from: geometry), height: 40)
                    .background(Color(.lightGray))
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .onChange(of: text, perform: handleInput)
                    .padding(.leading, 8)
                    .padding(.bottom, 4)
                    .background(backgroundView())
                    .offset(getInputOffset(geometry))
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
//        return max(g.size.width - x - 10, 80)
        let spaceLeft = w - lastX - 10
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
    @State var selected: Bool = false
    var text: String
    
    public var body: some View {
        Text(text)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .font(.body)
            .background(color)
            .foregroundColor(selected ? Color.white : .black)
            .cornerRadius(8)
            .onChange(of: selected, perform: { active in
                self.color = active ? .red : .gray
            })
    }
}
