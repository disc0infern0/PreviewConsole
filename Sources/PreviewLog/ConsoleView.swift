//
//  ConsoleView.swift
//
//  Created by Andrew on 02/10/2021.
//

import SwiftUI
import Combine

var Logger = ConsoleVM()

#if DEBUG
public var log = Logger.log
public var Log = Logger.Log
#else
public var log = Swift.print
public var Log: (@autoclosure () -> Any) -> EmptyView = { e in
    Swift.print(e())
    return EmptyView()
}
#endif

class ConsoleVM: ObservableObject {
    /// Defines the log(_:) and Log(_:) methods invocable in the view to be debugged
    @Published var messages: [Message] = []
    @Published var newMessageId: String? //trigger for autoscrolling
    enum ConsoleConstants { static let maximumMessages = 200 }

    public func Log(_ expression: @autoclosure () -> Any ) -> EmptyView {
        self.log(expression() )
        return EmptyView()
    }

    public func log(_ expression: @autoclosure () -> Any, _ messageType: MessageType = .debug ) {
        let text = "\(expression())"

        guard (text.count > 0) else { return }
        Swift.print(text)
        let message = Message(text: text, messageType: messageType)
        messages.append(message)
        if messages.count > ConsoleConstants.maximumMessages {
            messages.removeFirst()
        }
        self.newMessageId = message.id // triggers onChange view update
    }
}

struct ConsoleView: View {
    @ObservedObject var consoleVM = Logger

    var targetMessage: Message?

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { scrollView in
                ReversedScrollView() {
                    ForEach(consoleVM.messages) { message in
                        MessageView(message: message)
                            .transition(.move(edge: .bottom))
                    }
                }
                .padding(.horizontal)
                .onChange(of: consoleVM.newMessageId) { id in
                    if let id = id {
                        consoleVM.newMessageId = nil
                        withAnimation(.default) {
                            scrollView.scrollTo(id)
                        }
                    }
                }
            }.background(Color.green)
        }.edgesIgnoringSafeArea(.vertical)
    }
}

struct MessageView: View {
    var message: Message
    var body: some View {
        HStack {
            Text(message.text)
                .font(.custom("Helvetica", size: 14, relativeTo: .body))
                .foregroundColor(message.messageType.color())
            Spacer()
        }
        /* //One glorious day.. swipeActions will be allowed for items in a ScrollView?
        .swipeActions() {
            Button(role: .cancel, action: {} )
            {
                Text("\(message.created, formatter: Date.formatter)")
                    .font(.system(size:13))
                    .padding(6)
                    .foregroundColor(MessageType.info.color())
                    .background(Color.teal)
            }
        }
         */
    }
}
extension Date {
    static var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}
public enum MessageType {
    case info, debug, trace
    func color() -> Color {
        switch (self) {
            case .info: return Color.white
            case .debug: return Color.black
            case .trace: return Color.yellow
        }
    }
}
struct Message: Identifiable, Equatable {
    let id = UUID().uuidString
    var text: String
    let created = Date()
    var messageType: MessageType
}


struct ReversedScrollView<Content: View>: View {
    var leadingSpace: CGFloat = 10
    var content: Content

    init(@ViewBuilder content: ()->Content) {
        self.content = content()
    }
    var body: some View {
        GeometryReader { proxy in
            ScrollView() {
                VStack(spacing: 2) {
                    Spacer(minLength: leadingSpace)
                    content
                }
                .frame( minHeight: proxy.size.height )
            }
            .padding(.vertical, 2)
            .padding( .horizontal, 4)
        } .edgesIgnoringSafeArea(.all) //.vertical)
    }
}
