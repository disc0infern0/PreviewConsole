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

/* Create a view extension per below if you want to see the preview console in the simulator
 // add .console() to the main view.
 public extension View {
 	func console() -> some View {
 		ZStack {
 			self
 			PullUp( Console() )
 		}
 		.previewDisplayName("Debugger's log") //  Stardate 4523.3
 	}
 }
 */

postfix operator .|

public extension PreviewProvider {
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

   static postfix func .| ( lhs: Self) -> some View where Self: View {
      console( lhs )
   }
}

struct PullUp<Content: View>: View {
   var content: Content
   @StateObject
   var viewmodel = PullUpVM()
   @State var timer: Timer?
   var body: some View {
      GeometryReader { geo in
         ZStack(alignment: .bottom ) {
            Color.clear
            VStack(spacing: 0) {
               PullUpBar()
               content
            }
            .animation(.easeIn(duration: 0.75), value: viewmodel.isUp )  // animate open/close  (not dragging!)
            .environmentObject(viewmodel)  // Pass viewmodel into enviroment for reference by wrapped view
         }.onAppear {
            viewmodel.setScreenHeight(to: geo.size.height)
            let i = 0.42
            timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
               if viewmodel.unreadMessages {
                  withAnimation(.easeIn(duration: i)) { viewmodel.arrowFraction = 0.5 }
                  withAnimation(.easeOut(duration: i).delay(i)) { viewmodel.arrowFraction = viewmodel.frameHeight > 0 ? 1.5 : 0.0 }
                  withAnimation(.easeIn(duration: i).delay(i*2)) { viewmodel.arrowFraction = 0.5 }
                  withAnimation(.easeOut(duration: i).delay(i*3)) { viewmodel.arrowFraction = viewmodel.frameHeight > 0 ? 1.0 : 0.0 }
               }
            }

         }
      }
      .edgesIgnoringSafeArea(.all)
   }
   init(_ wrapped: Content) {
      content = wrapped
   }
}

/// ViewModel for setting the frameheight of the console.
final class PullUpVM: ObservableObject {
   // Default height to rise to when opened
   var lastFrameHeight: CGFloat = 142
   // Lists make the height jump around at top of screen, so avoid it with a maxHeight
   var maxHeight: CGFloat { screenHeight - pullBarHeight - 30 }
   let pullBarHeight: CGFloat = 26
   var unreadMessages = false
   @Published
   var frameHeight: CGFloat = 0
   @Published
   var arrowFraction: Double = 0 // { frameHeight > 0 ? 1.0 : 0.0 }
   init() {
		$frameHeight.map { $0 > 0 ? 1 : 0 }
         .assign(to: &$arrowFraction)
   }

   // toggle up/down if handle is tapped
   func tapped() {
      if isUp {
         lastFrameHeight = frameHeight
         frameHeight = 0
      } else { frameHeight = lastFrameHeight }
   }

   // Default initial screenHeight setting will be overwritten by Geometry Reader
   var screenHeight: CGFloat = 800
   /// Geometry Reader will call this.
   func setScreenHeight(to screenHeight: CGFloat) {
      self.screenHeight = screenHeight
   }

   // isUp and isDragging are used by Console() to automagically [i.e. .onChange() ]
   // reposition the List to the last value after these values change
   var isUp: Bool { frameHeight > 0 }

   @Published var isDragging: Bool? = false
   var drag: some Gesture {
      DragGesture()
         .onChanged { [weak self] value in
				// adjust frameHeight by drag translation height, but keep onscreen
            if let self = self {
               self.frameHeight = (self.frameHeight-value.translation.height).between(0...self.maxHeight )
               self.isDragging = nil
            }
         }
         .onEnded { [weak self] _ in
               self?.isDragging = false
         }
   }
}

/// Composite view that sits on top of the wrapped view/console
/// A rounded horizontal bar, with an overlayed grab handle
/// Click the handle to open/close the console
/// Drag the bar to reposition the view to show as much of the console as required.
struct PullUpBar: View {
   @EnvironmentObject var viewmodel: PullUpVM

   var body: some View {
      barBackground
         .overlay(handle)
         .frame(height: viewmodel.pullBarHeight, alignment: .bottom)
         .gesture(viewmodel.drag)
         .accessibilityLabel("Drag")
   }

   /// Take the top half of a rounded rectangle so that
   /// the bottom edge (formerly the middle of the rectangle)
   /// will be flush to the view beneath it.
   var barBackground: some View {
      RoundedRectangle(cornerRadius: viewmodel.pullBarHeight)
         .fill(Color.gray)
         .frame(height: viewmodel.pullBarHeight*2)
         .frame(height: viewmodel.pullBarHeight, alignment: .top)
         .clipped() // Not strictly necessary since will be overwritten.
   }

   /// Display a 'fancy' handle that points in the direction that the view can be
   /// opened or minimised.
   var handle: some View {
      HandleShape(fraction: viewmodel.arrowFraction )
         .stroke(Color.secondary, style: StrokeStyle(lineWidth: viewmodel.pullBarHeight/6, lineCap: .round, lineJoin: .round))
         .frame(height: viewmodel.pullBarHeight * 0.32) // governs height of triangle centre
         .onTapGesture { viewmodel.tapped() }
         .accessibilityLabel("Toggle console")
         .accessibilityAction(named: Text(viewmodel.isUp ? "Close console" : "Open console"), viewmodel.tapped)
   }
}

/// The triangle at the centre of the shape indicates the direction the view will move in when clicked.
/// The Handle shape should automatically scale to  20% of available width, and be symmetrical about the centre.
/// Of the 10% on each side of the center, the outer line is  8% , leaving 2% about the  centre for the triangle
struct HandleShape: Shape {
   var fraction: Double // 1 max  0 min
   // Make the centre point of the shape animate up and down
   // Most people won't notice, but.. it's the little things you know?
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

/// Range checking
extension Comparable {
   /// returns a value of self limited between the upper and lower bounds of the supplied range
   func between(_ range: ClosedRange<Self>) -> Self {
      min(range.upperBound, max(self, range.lowerBound))
   }
}

#else
// Production code.. still needs a call to console { } for syntactic compliance,
// but since this is an extension of PreviewProvider
// it will be eliminated in the compiler for production.

public extension PreviewProvider {
   /// Add a pull-up console. Invoke with console { ... }
   static func console<Content: View>(@ViewBuilder yourContent: () -> Content) -> some View {
         yourContent()
   }
   /// Add a pull-up console. Invoke with console( ViewName() )
   static func console<Content: View>(_ yourContent: Content) -> some View {
         yourContent
   }
}


#endif
