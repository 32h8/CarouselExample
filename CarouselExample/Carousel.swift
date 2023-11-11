//
//  Carousel.swift
//  CarouselExample
//
//  Created by Maciej Matyasik on 17/04/2023.
//

import SwiftUI

private struct WidthPreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    
    static var defaultValue: CGFloat = .zero
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct SizePreferenceKey<Item: Hashable>: PreferenceKey {
    typealias Value = [Item: CGSize]
    
    static var defaultValue: Value { [:] }
    
    static func reduce(
        value: inout Value,
        nextValue: () -> Value
    ) {
        value.merge(nextValue()) { $1 }
    }
}

struct Carousel<Data, ID, Content>: View where Data: RandomAccessCollection, ID: Hashable, Content: View {
        
    private let data: Data
    private let idKeyPath: KeyPath<Data.Element, ID>
    private let spacing: Double
    private let content: (Data.Element, _ batch: Int) -> Content
    
    @State private var elemCount: Int = 1
    @State private var elemOffset: Int = 0
    
    // positive offset moves toward trailing edge
    // negative offset moves toward leading edge
    @Binding var xOffset: Double
    let maxOffsetAbsDelta: Double // value to prevent element from dissapearing to early
    
    @State private var preferences: [Wrapped.NewID: CGSize] = [:]
        
    init(_ data: Data,
         id: KeyPath<Data.Element, ID>,
         spacing: Double = 10,
         xOffset: Binding<Double>,
         maxOffsetAbsDelta: Double = 50.0,
         @ViewBuilder content: @escaping (Data.Element, _ batch: Int) -> Content
    ) {
        self.data = data
        self.idKeyPath = id
        self.spacing = spacing
        self._xOffset = xOffset
        self.maxOffsetAbsDelta = maxOffsetAbsDelta
        self.content = content
    }

    var body: some View {
        VStack {
//            Text("wrappedData count: \(wrappedData.count)") // for debuging
            GeometryReader { geo in
                HStack(spacing: spacing) {
                    ForEach(wrappedData) { wrapped in
                        content(wrapped.elem, wrapped.id.batch)
                            .anchorPreference(key: SizePreferenceKey.self, value: .bounds) { anchor in
                                // we collect all elements sizes
                                [wrapped.id: geo[anchor].size]
                            }
                    }
                }
                .fixedSize()
                .anchorPreference(
                    key: WidthPreferenceKey.self,
                    value: .bounds) { anchor in
                        let width = geo[anchor].size.width
                        return width - abs(xOffset)
                    }
                .onPreferenceChange(SizePreferenceKey<Wrapped.NewID>.self) { sizes in
                    preferences = sizes
                }
                .onPreferenceChange(WidthPreferenceKey.self) { value in
                    // adds element till avaliable space is filled
                    // starts adding elements in advance to solve glitch in animation of new element
                    // we make sure that added element is not visible yet
                    let advance = maxOffsetAbsDelta
                    if value < geo.size.width + advance {
                        elemCount += 1
                    } else {
                        // removes not visible elements
                        trimElements()
                    }
                }
                .offset(x: xOffset)
                .frame(
                    width: geo.size.width,
                    height: geo.size.height,
                    alignment: xOffset >= 0 ? .trailing : .leading)
            }
            .clipped() // comment to debug
        }
    }
    
    // to prevent excessive growth we remove elements that are out of sight
    private func trimElements() {
        if xOffset > 0 {
            // removes last element if possible
            if let lastElemId = wrappedData.last?.id,
               let lastElemSize = preferences[lastElemId] {
                
                // by adding max delta we make sure that element
                // was fully invisible before most recent move
                // otherwise element will disappear too early
                if xOffset > lastElemSize.width + maxOffsetAbsDelta {
                    xOffset -= lastElemSize.width + spacing
                    elemCount -= 1
                    elemOffset += 1
                }
            }
        } else {
            // removes first element if possible
            if let firstElemId = wrappedData.first?.id,
               let firstElemSize = preferences[firstElemId] {
                
                if abs(xOffset) > firstElemSize.width + maxOffsetAbsDelta {
                    xOffset += firstElemSize.width + spacing
                    elemCount -= 1
                    elemOffset += 1
                }
            }
        }
    }
    
    private var wrappedData: [Wrapped] {
        if xOffset >= 0 {
            // data when content moving toward trailing edge
            return wrappedDataForTrailing
        } else {
            // data when content moving toward leading edge
            return wrappedDataForLeading
        }
    }
    
    private var wrappedDataForLeading: [Wrapped] {
        precondition(data.count > 0)
        var res: [Wrapped] = []
        res.reserveCapacity(elemCount)
                
        for i in 0..<elemCount {
            let i = i + elemOffset
            let (batch, idx) = i.quotientAndRemainder(dividingBy: data.count)
            
            let elemIdx = data.index(data.startIndex, offsetBy: idx)
            let elem = data[elemIdx]
            
            // because there can be multiple the same elements, we wrap them so
            // they have different id's
            let wrapped = Wrapped(elem: elem, id: idKeyPath, batch: batch)
            res.append(wrapped)
        }
        return res
    }
    
    private var wrappedDataForTrailing: [Wrapped] {
        precondition(data.count > 0)
        var res: [Wrapped] = []
        res.reserveCapacity(elemCount)
        let reversedData = data.reversed()
                
        for i in 0..<elemCount {
            let i = i + elemOffset
            let (batch, idx) = i.quotientAndRemainder(dividingBy: data.count)
            
            let elemIdx = reversedData.index(reversedData.startIndex, offsetBy: idx)
            let elem = reversedData[elemIdx]

            // because there can be multiple the same elements, we wrap them so
            // they have different id's
            let wrapped = Wrapped(elem: elem, id: idKeyPath, batch: batch)
            res.append(wrapped)
        }
        return res.reversed()
    }
    
    private struct Wrapped: Identifiable {
        var elem: Data.Element
        var id: NewID
        
        init(elem: Data.Element, id: KeyPath<Data.Element, ID>, batch: Int) {
            self.elem = elem
            self.id = .init(originalId: elem[keyPath: id], batch: batch)
        }
        
        struct NewID: Hashable {
            let originalId: ID
            let batch: Int // used to distinguish elements with the same originalId
        }
    }
}

struct CarouselPreview: View {
    @State private var words: [String] = (1...3).map { "\($0)" }
    @State private var xOffset1: Double = 0.1
    @State private var xOffset2: Double = -0.1

    static let interval: TimeInterval = 0.2
    @State private var timer = Timer.publish(every: interval, on: .main, in: .common).autoconnect()
    @State private var runNum: Int = 0
    
    var body: some View {
        VStack {
            buttons
            Text(String(format: "xOffset1: %.1f", xOffset1))
            GeometryReader { geo in
                carousel1
                .border(.red, width: 1.0)
                .frame(width: geo.size.width * 0.8)
                .frame(width: geo.size.width, height: geo.size.height)
                .onReceive(timer) { _ in
                    withAnimation(.linear(duration: Self.interval)) {
                        xOffset1 += 10
                    }
                }
            }
            .frame(height: 200)
            Text(String(format: "xOffset2: %.1f", xOffset2))
            GeometryReader { geo in
                carousel2
                .border(.red, width: 1.0)
                .frame(width: geo.size.width * 0.8)
                .frame(width: geo.size.width, height: geo.size.height)
                .onReceive(timer) { _ in
                    withAnimation(.linear(duration: Self.interval)) {
                        xOffset2 -= 10
                    }
                }
            }
            .frame(height: 200)
        }
        .id(runNum)
    }
    
    @ViewBuilder
    private var buttons: some View {
        Group {
            Button("Reset") {
                runNum += 1
                xOffset1 = 0
                xOffset2 = -0.1
            }
            Button("Pause") {
                timer.upstream.connect().cancel()
            }
            Button("Resume") {
                timer = Timer.publish(every: Self.interval, on: .main, in: .common).autoconnect()
            }
        }
        .font(.title)
    }
    
    @ViewBuilder
    private var carousel1: some View {
        Carousel(words.reversed(), id: \.self, xOffset: $xOffset1) { (str, batch: Int) in
            VStack {
                Text(str)
                Text("batch: \(batch)")
            }
            .frame(width: 100, height: 100)
            .background(Color.orange)
            .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private var carousel2: some View {
        Carousel(words, id: \.self, xOffset: $xOffset2) { (str, batch: Int) in
            VStack {
                Text(str)
                Text("batch: \(batch)")
            }
            .frame(width: 100, height: 100)
            .background(Color.green)
            .cornerRadius(8)
        }
    }
}

struct CarouselExample2_Previews: PreviewProvider {
    static var previews: some View {
        CarouselPreview()
    }
}
