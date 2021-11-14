//
//  PreviewConsole.swift
//
///  A resizeable wrapper  that you can pull up from the bottom of the screen, and which
///  wraps, in this package, a console view of log messages, although it could be used to wrap anything.
///  The size is adjusted by modification of the frame height, rather than an offset
///  so that the bottom of the screen is always visible.
///  The view will always start in the down position,
///  but can be brought up or minimised by clicking the middle bar on the header.
///  The bar header can also be dragged into the desired position.
//
//  Created by Andrew on 05/10/2021.

// MIT License. See LICENSE file attached.
// 
//
// swiftlint:disable identifier_name

import SwiftUI

#if DEBUG

public extension View {
  func console() -> some View {
    ZStack {
      self
      PullUp( Console() )
    }
    .previewDisplayName("Debugger's log") //  Stardate 4523.3
  }
}
extension PreviewProvider {
  /// Add a pull-up console. Invoke with console { ... }
  static func console<Content: View>(@ViewBuilder yourContent: () -> Content) -> some View {
    ZStack {
      yourContent()
      PullUp( Console() )
    }
    .previewDisplayName("Debugger's log") //  Stardate 4523.3
  }
  /// Add a pull-up console. Invoke with console( ViewName() )
  static func console<Content: View>(_ yourContent: Content) -> some View {
    ZStack {
      yourContent
      PullUp( Console() )
    }
    .previewDisplayName("Debugger's log") //  Stardate 4523.3
  }
}

struct PullUp<Content: View>: View {
  var content: Content
  @StateObject var vm = PullUpVM()
  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .bottom ) {
        Color.clear
        VStack(spacing: 0) {
          PullUpBar()
          content
        }
        .animation(.easeIn(duration: 0.42), value: vm.isUp )  // animate open/close  (not dragging!)
        .environmentObject(vm) // Pass viewmodel into enviroment for reference by wrapped view
      }.onAppear { vm.setScreenHeight(to: geo.size.height) }
    }
    .edgesIgnoringSafeArea(.all)
  }
  init(_ wrapped: Content) {
    content = wrapped
  }
}

/// ViewModel for setting the frameheight of the console.
final class PullUpVM: ObservableObject {
  var lastFrameHeight: CGFloat = 142   // Default height to rise to when opened
  // Lists make the height jump around at top of screen, so avoid it with a maxHeight
  var maxHeight: CGFloat { screenHeight - pullBarHeight - 30 }
  let pullBarHeight: CGFloat = 26
  @Published var frameHeight: CGFloat = 0

  // toggle up/down if handle is tapped
  func tapped() {
    if isUp {
      lastFrameHeight = frameHeight
      frameHeight = 0
    } else { frameHeight = lastFrameHeight }
  }

  // Default initial screenHeight setting will be overwritten by Geometry Reader
  var screenHeight: CGFloat = 800 //UIScreen not available in Package.
  /// Geometry Reader will call this.
  func setScreenHeight(to screenHeight: CGFloat) {
    self.screenHeight = screenHeight
  }

  // isUp and isDragging are used by Console() to automagically
  // reposition the List to the last value after these values change
  var isUp: Bool { frameHeight > 0 }
  @Published var isDragging: Bool? = false
  var drag: some Gesture {
    DragGesture()
      .onChanged { [weak self] value in
        if let self = self { // adjust frameHeight by drag translation height, but keep onscreen
          self.frameHeight = (self.frameHeight-value.translation.height).between(0...self.maxHeight )
          self.isDragging = nil
        }
      }
      .onEnded { [weak self] _ in
        if let self = self { self.isDragging = false }
      }
  }
}

/// Composite view that sits on top of the wrapped view/console
/// A rounded horizontal bar, with an overlayed grab handle
/// Click the handle to open/close the console
/// Drag the bar to reposition the view to show as much of the console as required.
struct PullUpBar: View {
  @EnvironmentObject var vm: PullUpVM

  var body: some View {
    barBackground.overlay(handle)
      .frame(height: vm.pullBarHeight, alignment: .bottom)
      .gesture(vm.drag)
      .accessibilityLabel("Drag")
  }

  // Take the top half of a rounded rectangle so that
  // the bottom edge (formerly the middle of the rectangle)
  // will be flush to the view beneath it.
  var barBackground: some View {
    RoundedRectangle(cornerRadius: vm.pullBarHeight)
      .fill(Color.gray)
      .frame(height: vm.pullBarHeight*2)
      .frame(height: vm.pullBarHeight, alignment: .top)
      .clipped() // Not strictly necessary since will be overwritten.
  }

  /// Display a 'fancy' handle that points in the direction that the view can be
  /// opened or minimised.
  var handle: some View {
    HandleShape(fraction: vm.isUp ? 1.0 : 0.0 )
      .stroke(Color.secondary, style: StrokeStyle(lineWidth: vm.pullBarHeight/6, lineCap: .round, lineJoin: .round))
      .frame(height: vm.pullBarHeight * 0.32) // governs height of triangle centre
      .onTapGesture { vm.tapped() }
      .accessibilityLabel("Toggle console")
      .accessibilityAction(named: Text(vm.isUp ? "Close console" : "Open console"), vm.tapped)
  }
}

/// The triangle at the centre of the shape indicates the direction the view will move in when clicked.
/// The Handle shape should automatically scale to  20% of available width, and be symmetrical about the centre.
/// Of the 10% on each side of the center, the outer line is  8% , leaving 2% about the  centre for the triangle
struct HandleShape: Shape {
  var fraction: Double // 1 max  0 min
                       // Make the centre point animate up and down
  var animatableData: Double {
    get { return fraction }
    set { fraction = newValue }
  }

  func path(in rect: CGRect) -> Path {
    let sideLength: CGFloat = rect.maxX * 0.08
    let triangleCenter: CGFloat = rect.maxX * 0.02
    var centreY: Double {
      rect.minY + fraction * (rect.maxY - rect.minY)
    }

    var path=Path()
    var x: CGFloat = rect.maxX * (0.5 - 0.08 - 0.02 )
    path.move(to: CGPoint(x: x, y: rect.midY))
    x += sideLength // first horizontal
    path.addLine(to: CGPoint(x: x, y: rect.midY))
    x += triangleCenter // to triangle point
    path.addLine(to: CGPoint(x: x, y: centreY))
    x += triangleCenter // to lower rhs of triangle
    path.addLine(to: CGPoint(x: x, y: rect.midY))
    x += sideLength // to end of second horizontal
    path.addLine(to: CGPoint(x: x, y: rect.midY))

    return path
  }
}

// Some people are going to get mad at this //
extension Numeric {
  /// C style convenience to add 1 to self
  static postfix func ++ ( num: inout Self) {
    num += 1
  }
}
/// Range checking
extension Comparable {
  /// returns a value of self limited between the upper and lower bounds of the supplied range
  func between(_ range: ClosedRange<Self>) -> Self {
    min(range.upperBound, max(self, range.lowerBound))
  }
}

#endif
