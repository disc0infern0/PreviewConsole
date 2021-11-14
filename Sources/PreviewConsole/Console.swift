//
//  Console.swift
//
//  Created by Andrew on 02/10/2021.
//
// MIT License. See LICENSE file attached.

/// Shows a scrollable list of any expressions that are sent to print(), log(:), for imperative,  or Log(:) ,
///  for declarative,  code.
///  It is designed to allow viewing of print statements within the Xcode preview, in a similar fashion
///  to how you view messages in the Xcode console when running the simulator.
/// 

// swiftlint:disable identifier_name

import SwiftUI

#if DEBUG
// Probably way too many print() overloads, but attempting to cover all bases!
public func print(_ object: Any...) {
  for item in object {
    log(item)
  }
}
public func print(_ object: Any ) {
  log(object)
}
public func print(_ text: String ) {
  log( text )
}
public func print(_ expression: @escaping () -> String ) {
  log( expression() )
}
public func log(
  _ expression: @autoclosure () -> Any,
  _ messageType: MessageType = .debug   ) {
    let text = "\(expression())"
    Task { await ConsoleVM.shared.log( text, messageType: messageType) }
  }
/// Place a message on the console (both in Preview and Simulator) , and return an EmptyView
/// callable in view composition code
public func Log(
  _ expression: @autoclosure () -> Any,
  _ messageType: MessageType = .debug ) -> EmptyView {
    let text = "\(expression())"
    Task { await ConsoleVM.shared.log( text, messageType: messageType) }
    return EmptyView()
  }
#else
public var log = {}
public var Log: (@autoclosure () -> Any) -> EmptyView = { _ in
  return EmptyView()
}
#endif

#if DEBUG

struct Defaults {
  static let backgroundColour: Color = .primary

  static let numberOfBlankLines: Int = 42
  static let maximumMessageCount: Int = 4200

  static let rowHeight: CGFloat = 10

}
/// View model for the console. Implements log(_:_:)
///  Defines the log array (messages) and initialiser
@MainActor
final class ConsoleVM: ObservableObject {
  static var shared = ConsoleVM()
  @Published var messages: [Message] = []

  /// Place a message on the console;, both the Preview pull up console and on the Simulator console
  /// Please use Log(_:_:) if you need to log a message in View composition code
  public func log(_ text: String, messageType: MessageType) {
    guard !text.count.words.isEmpty else { return }  // abort silently if expression is empty
                                                     // Also log to standard console
    let stringDate =
    Date.now.formatted(date: .omitted, time: .standard)
    Swift.print("text   @ \(stringDate)")
    // append new log message to our message array
    messages.append(Message(text: text, messageType: messageType ))
    // Cap messages array at specified maximum number of messages
    if messages.count > Defaults.maximumMessageCount {
      messages = Array(messages.dropFirst())
      // alt .suffix(Defaults.maximumMessageCount))
    }
  }

  init() {
    guard Defaults.numberOfBlankLines < Defaults.maximumMessageCount else {
      fatalError("Number of blank lines must be less than maximum message count")
    }
    // Initialise List with blanks so that there are enough lines
    // for new log messages to appear at the bottom of the screen.
    for _ in (0..<Defaults.numberOfBlankLines) {
      messages.append(Message())
    }
  }
}

/// The core view: List of all messages
/// Display a list of message inside a scrollView reader to allow automatic positioning of the list to the last
/// message in the array.
/// Display an individual msg with swipe to view date.created
struct Console: View {
  @ObservedObject var consoleVM = ConsoleVM.shared
  @EnvironmentObject var pullUpVM: PullUpVM

  var body: some View {
    ScrollViewReader { proxy in
      List {
        ForEach(consoleVM.messages) { msg in
          ConsoleRow(msg: msg)
        }
      }
      .listStyle(.plain)
      .onChange(of: consoleVM.messages) {_ in scrollToBottom(proxy) }  // Messages added
      .onChange(of: pullUpVM.isUp) {_ in scrollToBottom(proxy) } // open/close
      .onChange(of: pullUpVM.isDragging) {_ in scrollToBottom(proxy) } // drag change
    }
    .frame(height: pullUpVM.frameHeight)
    .background(Defaults.backgroundColour)
    .environment(\.defaultMinListRowHeight, Defaults.rowHeight)
    .edgesIgnoringSafeArea(.all)
  }

  /// Place the last line in the messages array
  /// at the bottom of screen.
  /// The ScrollViewProxy will always ignore the safe area, so on
  /// iOS, iPadOS, put the last but one message on the "bottom", so that the
  /// actual last line is shown below it
  func scrollToBottom(_ proxy: ScrollViewProxy ) {
    guard consoleVM.messages.count > 1 else { return }
    let count = consoleVM.messages.count-1
    let lastMessage = consoleVM.messages[count-1]
    proxy.scrollTo(lastMessage.id, anchor: .bottom)
  }
}

///  Console Row with preferred list settings
struct ConsoleRow: View {
  var msg: Message
  var body: some View {
    messageText()
      .foregroundColor(msg.messageType.color)
      .listItemTint(msg.messageType.color)
      .listRowInsets(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
      .listRowBackground(Defaults.backgroundColour)
  }

  /// Include time message was logged on message line if swipeAction is not available
  @ViewBuilder
  func messageText() -> some View {
    let stringDate =
    Date.now.formatted(date: .omitted, time: .standard)
    if #available(iOS 15, macOS 12, *) {
      Text("\(msg.text)")
        .font(.body)
        .swipeActions(allowsFullSwipe: false) {
          Button {} label: {
            Text("@ \(stringDate)")
              .font(.callout)
              .padding()
          }
          .tint(msg.messageType.color)
          .accessibilityHint(Text("Reveals the time that the message was logged"))
          .accessibilityLabel("swipe")
        }
    } else {
      Text("\(msg.text) ").font(.body) + Text("@ \(stringDate)").font(.callout)
    }
  }
}

/// Support .info, .debug and .trace  message types, which affect the color in the log
public enum MessageType {
  case info, debug, trace

  var color: Color {
    switch self {
      case .info:   return Color.indigo
      case .debug:  return Color.green
      case .trace:  return Color.yellow
    }
  }
}

/// Message meta-data and text
struct Message: Identifiable, Equatable, Hashable {
  let id = UUID().uuidString
  var text: String = ""
  let created = Date()
  var messageType: MessageType = .debug
}
#endif
