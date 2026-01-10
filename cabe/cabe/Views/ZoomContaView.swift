//
//  ContaZoomView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 22/12/25.
//

import SwiftUI

struct ZoomContaView: View {
    @State private var contas: [ContaModel] = []

    @Binding var contaSelecionada: ContaModel?
    @Environment(\.dismiss) private var dismiss

    private let repository = ContaRepository()

    var body: some View {
        List(contas) { conta in
            HStack {
                Text(conta.nome)
                Spacer()
                if conta.id == contaSelecionada?.id {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
            .listStyle(.insetGrouped)
            .onTapGesture {
                contaSelecionada = conta
                dismiss()
            }
        }
        .navigationTitle("Contas")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            carregarContas()
        }
        .overlay(
            Group {
                if contas.isEmpty {
                    Text("Nenhuma conta encontrado")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        )
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

    private func carregarContas() {
        do {
            contas = try repository.listar()
        } catch {
            print("Erro ao listar contas:", error)
            contas = []
        }
    }
}
