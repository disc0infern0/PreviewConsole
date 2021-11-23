//
//  SwiftUIView.swift
//  ListConsole
//
//  Created by Andrew on 12/10/2021.
//

import SwiftUI

struct PreviewConsoleExample: View {
  @State var counter = 1
  var body: some View {
    VStack {
      Text("Hi Logger!")
      Log("help! \(7*6) printed from Log") // uses default .debug

      Button("Add an info log message") {
        log("Log \(counter). Swipe to see time of log ", .info )
        counter++
      }
      .buttonStyle(.borderedProminent)

      Button("Add a trace message") {
        log("Tracing counter.\(counter)  (swipe to see time of trace) ", .trace )
        counter++
      }
      .buttonStyle(.borderedProminent)

      Button("Add a debug message") {
        print("Debugger's Log. Stardate 4523.3\(counter)  ")
        counter++
      }
      .buttonStyle(.borderedProminent)
    }
  }
}

struct SwiftUIView_Previews: PreviewProvider {
  static var previews: some View {
    console {
      PreviewConsoleExample()
    }
  }
}

extension Numeric {
   /// For Kernighan and Ritchie, who set me on my coding journey
   static postfix func ++ ( num: inout Self) {
      num += 1
   }
}
