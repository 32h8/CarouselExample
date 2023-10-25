//
//  TimelineCarousel.swift
//  CarouselExample
//
//  Created by Maciej Matyasik on 25/10/2023.
//

import SwiftUI

struct TimelineCarousel: View {
    
    static let interval: TimeInterval = 0.2
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: Self.interval)) { timeline in
            MyCarousel(date: timeline.date)
        }
        .border(.red)
    }
    
    private struct MyCarousel: View {
        let date: Date
        @State private var xOffset: Double = 0.1
        private let words: [String] = (1...3).map { "\($0)" }
        
        var body: some View {
            Carousel(words.reversed(), id: \.self, xOffset: $xOffset) { (str, batch: Int) in
                VStack {
                    Text(str)
                    Text("batch: \(batch)")
                }
                .frame(width: 100, height: 100)
                .background(Color.yellow)
            }
            .onChange(of: date) { _ in
                xOffset += 20
            }
            .animation(.linear(duration: TimelineCarousel.interval), value: date)
        }
    }
}

struct TimelineCarousel_Previews: PreviewProvider {
    static var previews: some View {
        TimelineCarousel()
            .previewDisplayName("timeline")
    }
}
