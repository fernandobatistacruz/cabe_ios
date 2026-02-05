//
//  ActivityView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 14/01/26.
//


import SwiftUI
import UIKit

struct ShareSheetView: View {

    let message: String
    let subject: String
    let fileURL: URL

    var body: some View {
        ActivityView(
            message: message,
            subject: subject,
            fileURL: fileURL
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    ShareSheetView(
        message: "Teste",
        subject: "Assunto",
        fileURL: URL(fileURLWithPath: "/dev/null")
    )
}

struct ActivityView: UIViewControllerRepresentable {

    let message: String
    let subject: String
    let fileURL: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {

        let content = ShareContent(
            message: message,
            subject: subject,
            fileURL: fileURL
        )

        let controller = UIActivityViewController(
            activityItems: [content, fileURL],
            applicationActivities: nil
        )

        return controller
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

final class ShareContent: NSObject, UIActivityItemSource {

    let message: String
    let subject: String
    let fileURL: URL

    init(message: String, subject: String, fileURL: URL) {
        self.message = message
        self.subject = subject
        self.fileURL = fileURL
    }

    // Placeholder obrigatório
    func activityViewControllerPlaceholderItem(
        _ activityViewController: UIActivityViewController
    ) -> Any {
        message
    }

    // Conteúdo por app
    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {

        switch activityType {

        case .mail:
            return message // corpo do email

        case .message:
            return message // iMessage

        default:
            // WhatsApp, Telegram, etc
            return message
        }
    }

    // Assunto só para Mail
    func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        subject
    }
}

struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}
