//
//  BannerView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 07/01/26.
//


import SwiftUI
import GoogleMobileAds

import SwiftUI

struct BannerView: View {

    @State private var isVisible = true
    let adUnitID: String

    var body: some View {
        if isVisible {
            ZStack(alignment: .topTrailing) {

                // Card
                VStack {
                    AdMobBannerView(adUnitID: adUnitID)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .frame(height: 50)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isVisible = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color(uiColor: .tertiarySystemBackground))
                        )
                }
                .padding(6)
            }
            .padding(.horizontal)
            .transition(.opacity)
        }
    }
}

struct AdMobBannerView: UIViewRepresentable {

    let adUnitID: String

    func makeUIView(context: Context) -> GoogleMobileAds.BannerView {
        let banner = GoogleMobileAds.BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = UIApplication.shared
            .connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?
            .rootViewController

        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: GoogleMobileAds.BannerView, context: Context) {}
}
