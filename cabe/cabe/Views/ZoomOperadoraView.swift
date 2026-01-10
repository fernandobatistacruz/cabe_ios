//
//  OperadoraZoomView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 22/12/25.
//

import SwiftUI

struct ZoomOperadoraView: View {
    @Binding var operadoraSelecionada: OperadoraCartao?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(OperadoraCartao.allCases) { operadora in
            HStack(spacing: 12) {
                Image(operadora.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)

                Text(operadora.nome)

                Spacer()

                if operadora == operadoraSelecionada {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
            .listStyle(.insetGrouped)
            .onTapGesture {
                operadoraSelecionada = operadora
                dismiss()
            }
        }
        .navigationTitle("Operadora")
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
