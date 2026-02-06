//
//  ToastModifier.swift
//  OpenfortAuthorization
//

import SwiftUI

enum ToastStyle {
    case success, error, info
}

struct ToastState: Equatable {
    let message: String
    let style: ToastStyle
    let persistent: Bool

    static func success(_ msg: String) -> ToastState {
        ToastState(message: msg, style: .success, persistent: false)
    }

    static func error(_ msg: String) -> ToastState {
        ToastState(message: msg, style: .error, persistent: false)
    }

    static func info(_ msg: String) -> ToastState {
        ToastState(message: msg, style: .info, persistent: false)
    }

    static func result(_ msg: String) -> ToastState {
        ToastState(message: msg, style: .success, persistent: true)
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var state: ToastState?
    let duration: TimeInterval

    func body(content: Content) -> some View {
        ZStack {
            content
            if let toast = state {
                if toast.persistent {
                    persistentToast(toast)
                } else {
                    autoToast(toast)
                }
            }
        }
    }

    private func autoToast(_ toast: ToastState) -> some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: iconName(for: toast.style))
                    .imageScale(.large)
                Text(toast.message)
                    .font(.subheadline)
                    .lineLimit(2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(backgroundColor(for: toast.style))
            .foregroundColor(.white)
            .clipShape(Capsule())
            .padding(.bottom, 24)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.25), value: state)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                withAnimation { state = nil }
            }
        }
        .zIndex(2)
    }

    private func persistentToast(_ toast: ToastState) -> some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { state = nil }
                }

            VStack(spacing: 12) {
                HStack {
                    Image(systemName: iconName(for: toast.style))
                        .imageScale(.large)
                    Text("Result")
                        .font(.headline)
                    Spacer()
                    Button {
                        withAnimation { state = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .imageScale(.large)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                ScrollView {
                    Text(toast.message)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)

                Button {
                    UIPasteboard.general.string = toast.message
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.white)

                Text("Tap anywhere to dismiss")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(20)
            .background(backgroundColor(for: toast.style))
            .foregroundColor(.white)
            .cornerRadius(16)
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.25), value: state)
        .zIndex(3)
    }

    private func iconName(for style: ToastStyle) -> String {
        switch style {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.octagon.fill"
        case .info: return "info.circle.fill"
        }
    }

    private func backgroundColor(for style: ToastStyle) -> Color {
        switch style {
        case .success: return Color.green.opacity(0.85)
        case .error: return Color.red.opacity(0.85)
        case .info: return Color.black.opacity(0.8)
        }
    }
}

extension View {
    func toast(_ state: Binding<ToastState?>, duration: TimeInterval = 2.5) -> some View {
        modifier(ToastModifier(state: state, duration: duration))
    }
}
