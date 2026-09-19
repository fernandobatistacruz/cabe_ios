//
//  ZoomIconeConta.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 19/09/26.
//

//
//  OperadoraZoomView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 22/12/25.
//

import SwiftUI

struct ZoomBancoView: View {
    @Binding var logo: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(BancoLogo.allCases
            .sorted {
                String(localized: $0.nome)
                    .localizedCompare(String(localized: $1.nome)) == .orderedAscending
            }) { banco in
            HStack(spacing: 12) {
                Image(banco.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)

                Text(banco.nome)

                Spacer()

                if banco.id == logo {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
            .listStyle(.insetGrouped)
            .onTapGesture {
                logo = banco.id
                dismiss()
            }
        }
        .navigationTitle("Banco")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
    }
}
