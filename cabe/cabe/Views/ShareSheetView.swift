//
//  ActivityView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 14/01/26.
//


import SwiftUI
import UIKit

struct ShareSheetView: View {

    let activityItems: [Any]

    var body: some View {
        ActivityView(activityItems: activityItems)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
    }
}

struct ActivityView: UIViewControllerRepresentable {
    
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }
    
    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}
