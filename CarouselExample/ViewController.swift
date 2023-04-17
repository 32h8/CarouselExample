//
//  ViewController.swift
//  CarouselExample
//
//  Created by Maciej Matyasik on 17/04/2023.
//

import UIKit
import SwiftUI

// https://www.youtube.com/watch?v=DgSLvIERY7s

class ViewController: UIViewController {

    private var urls1: [URL] = []
    private var urls2: [URL] = []
    private var urls3: [URL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadUrls()
        let childVC = UIHostingController(rootView: threeRowsView)
        addChild(childVC)
        view.addSubview(childVC.view)
        
        childVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            childVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            childVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            childVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadUrls() {
        // https://dummyimage.com/
        urls1 = (1...3)
            .reversed()
            .map { "https://dummyimage.com/200x100/c99e1e/0011ff.png&text=\($0)" }
            .compactMap(URL.init(string:))
        
        urls2 = (1...3)
            .map { "https://dummyimage.com/200x100/86c71e/0011ff.png&text=\($0)" }
            .compactMap(URL.init(string:))
        
        urls3 = (1...3)
            .reversed()
            .map { "https://dummyimage.com/200x100/5b9bc2/0011ff.png&text=\($0)" }
            .compactMap(URL.init(string:))
    }
    
    private var threeRowsView: some View {
        precondition(urls1.count > 0)
        precondition(urls2.count > 0)
        precondition(urls3.count > 0)
        return ThreeRows(urls1: urls1, urls2: urls2, urls3: urls3)
    }
}

private struct ThreeRows: View {
    let rowHeight: Double = 100.0
    
    let urls1: [URL]
    let urls2: [URL]
    let urls3: [URL]
    
    @State private var xOffset1: Double = 0
    @State private var xOffset2: Double = -0.1 // needs to be < 0
    @State private var xOffset3: Double = 0
    
    static let interval: TimeInterval = 0.2
    let timer = Timer.publish(every: interval, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 10) {
            Group {
                carousel1
                carousel2
                carousel3
            }
            .frame(height: rowHeight)
            .border(.red, width: 1)
        }
        .onReceive(timer) { _ in // note: don't attach onRecive to Group!
            withAnimation(.linear(duration: Self.interval)) {
                xOffset1 += 10
                xOffset2 -= 10
                xOffset3 += 10
            }
        }
    }
    
    @ViewBuilder
    private var carousel1: some View {
        Carousel(urls1, id: \.self, xOffset: $xOffset1) { (url, _) in
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 200, height: 100)
            .background(Color.orange)
            .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private var carousel2: some View {
        Carousel(urls2, id: \.self, xOffset: $xOffset2) { (url, _) in
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 200, height: rowHeight)
            .background(Color.green)
            .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private var carousel3: some View {
        Carousel(urls3, id: \.self, xOffset: $xOffset3) { (url, _) in
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 200, height: rowHeight)
            .background(Color.yellow)
            .cornerRadius(8)
        }
    }
}
