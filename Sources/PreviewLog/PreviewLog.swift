//
//  PreviewLog.swift

//
//  Dynamic frame sizing of an overlayed console of log messages
//  for use in the Xcode Preview.
//
//  Created by Andrew on 05/10/2021.
//  Copyright © 2021 Andrew Cowley. All rights reserved.
//
//  Inspired by Apple design and coding of BottomSheetView.swift, by Majid Jabrayilov
//  which uses an offset to move the view up onto the content
//  instead of changing the height.
// https://swiftwithmajid.com/2019/12/11/building-bottom-sheet-in-swiftui/
//
import SwiftUI

public extension PreviewProvider {
    @ViewBuilder
    static func makePreviewLog<Content: View>(for yourView: Content) -> some View   {
        ZStack {
            yourView
            PreviewLog()
        }.previewDisplayName("Debuggers Log")
    }
}

private struct PreviewLog : View {
    ///  PreviewLog creates a basic console for the Preview mode in Xcode, showing a scrollable list of any expressions that are sent to log(:), or Log(:) , for command and view composition modes respectively.
    ///  It is designed to work like the console in Xcode when running code in the simulator.
    ///  The view will always start in the down position, but can be brought up or minimised by clicking the middle bar on the header. The bar header can also be dragged into the desired position.
    @GestureState var translation: CGFloat = 0
    @State private var frameHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let maxHeight = geometry.size.height - 3 * Constants.pullBarHeight
            VStack(spacing: 0) {
                Spacer()
                PullUpBar(frameHeight: $frameHeight, screenWidth: geometry.size.width)
                ConsoleView()
                    .frame(
                        idealWidth: geometry.size.width,
                        idealHeight: frameHeight-translation,
                        alignment: .bottom )
                    .fixedSize()
            }
            .animation(.interactiveSpring(), value: frameHeight)
            .gesture(
                DragGesture().updating($translation) { value, state, _ in
                    state = value.translation.height
                }.onEnded { value in
                    frameHeight = min(maxHeight,frameHeight - value.translation.height )
                }
            )
        }.edgesIgnoringSafeArea(.all)
    }
}
