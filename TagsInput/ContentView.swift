 //
 //  TagsInput.swift
 //  TagsInput
 //
 //  Created by Garrett Wesley on 1/5/21.
 //
 
 import SwiftUI
 
 struct TagsInput: View {
    @State var tags: [String] = ["test"]
    @State var test = ""
    
    var body: some View {
        TagsController(tags: $tags, addTag: addTag, removeTag: removeTag, shouldAddTag: shouldAddTag)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue, lineWidth: 2)
            )
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
        let insets: EdgeInsets = .init(top: 6, leading: 12, bottom: 6, trailing: 12)
        let cornerRadius: CGFloat = 8
        let font: Font = .system(size: 14)
        
        let textColor: Color = .white
        let selectedTextColor: Color = .white
        let backgroundColor: Color = .gray
        let selectedColor: Color = .red
    }
    
    let tagItemOptions: TagItemOptions = TagItemOptions()
    let tintColor: Color = Color(UIColor.blue)
    let newTagCharacter: String = " "
    let spaceBetweenTags: CGFloat = 4
    let spaceBetweenLines: CGFloat = 4
    let placeholder: String = "Tags..."
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
    let addTag: (String) -> ()
    let removeTag: (Int) -> ()
    let shouldAddTag: (String, [String]) -> (Bool)
    let options: TagsOptions = TagsOptions()
    
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
                if shouldAddTag(tag, tags) && tag.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                    addTag(tag)
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
        } else if tags.count > 0 && text.count == 0 {
            selection = tags.count - 1
        }
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(tags.indices, id: \.self) { i in
                    Group {
                        TagItem(active: $selection, index: i, text: tags[i], options: options.tagItemOptions)
                    }
                    .onTapGesture {
                        selection = i
                    }
                    .padding(.trailing, options.spaceBetweenTags)
                    .padding(.bottom, options.spaceBetweenLines)
                    .background(backgroundView())
                    .offset(getOffset(at: i, geometry: geometry))
                }
                TagsTextField(text: $text, didDelete: didDelete)
                    .frame(width: getWidth(from: geometry), height: 30)
                    .onChange(of: text, perform: handleInput)
                    .padding(.horizontal, options.spaceBetweenLines)
                    .padding(.bottom, options.spaceBetweenLines)
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
        
        let spaceLeft = w - lastX - (options.spaceBetweenTags * 2)
        return spaceLeft > minWidth ? spaceLeft : w
    }
    
    private func getInputOffset(_ g: GeometryProxy) -> CGSize {
        guard sizes.count > 0 else { return .zero }
        print(sizes.count)
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
    var opts: TagsOptions.TagItemOptions
    var index: Int
    var text: String
    
    init(active: Binding<Int?>, index: Int, text: String, options: TagsOptions.TagItemOptions) {
        self._active = active
        self.text = text
        self.index = index
        self.opts = options
        self.color = options.backgroundColor
    }
    
    public var body: some View {
        Text(text)
            .padding(opts.insets)
            .font(opts.font)
            .background(color)
            .foregroundColor((active == index) ? opts.selectedTextColor : opts.textColor)
            .cornerRadius(opts.cornerRadius)
            .lineLimit(1)
            .truncationMode(.tail)
            .onChange(of: active, perform: { val in
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.color = val == index ? opts.selectedColor : opts.backgroundColor
                }
            })
    }
 }
