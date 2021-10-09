//
//  PullUpBar.swift
//  PreviewConsole
//
//  Created by Andrew on 06/10/2021.
//

import SwiftUI

enum Constants {
    static let radius: CGFloat = 16
    static let pullBarHeight: CGFloat = 22
    static let indicatorHeight: CGFloat = 6
    static let indicatorWidthRatio: CGFloat = 0.20
    static let defaultOpenHeight: CGFloat = 200
}
struct PullUpBar: View {
    @Binding var frameHeight: CGFloat
    @State private var lastFrameHeight: CGFloat = Constants.defaultOpenHeight

    var screenWidth: CGFloat //= UIScreen.main.bounds.width

    var barTop: some View {
        // Take the top half of a rounded rectangle so that
        // the bottom edge is flush to the view beneath it.
        Color(.gray)
            .frame(height:  2 * Constants.pullBarHeight )
            .cornerRadius(Constants.radius)
            .frame(height: Constants.pullBarHeight, alignment: .top)
            .clipped()
    }

    var handle: some View {
        // Small grab handle in the bar topper that can be clicked
        // to open/close. Always opening to last open position.
        RoundedRectangle(cornerRadius: Constants.radius)
            .fill(Color.secondary)
            .frame(
                width: Constants.indicatorWidthRatio * screenWidth,
                height: Constants.indicatorHeight,
                alignment: .top )
            .onTapGesture {
                lastFrameHeight = frameHeight>0 ? frameHeight : lastFrameHeight
                frameHeight = frameHeight == 0 ? lastFrameHeight : 0
            }
    }

    var body: some View {
        barTop .overlay(handle)
    }
}
