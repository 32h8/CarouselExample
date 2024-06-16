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
        private let words: [Int] = Array(1...5)
        
        var body: some View {
            Carousel(words, id: \.self, spacing: 0, xOffset: $xOffset) { (i, batch: Int) in
                VStack {
                    Text(String(i))
                    Text("batch: \(batch)")
                        .multilineTextAlignment(.center)
                }
                .frame(width: (i + batch) % 2 == 0 ? 100 : 70, height: 100)
                .background((i + batch) % 2 == 0 ? Color.yellow : Color.cyan)
            }
            .onChange(of: date) { _ in
                xOffset -= 40
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
