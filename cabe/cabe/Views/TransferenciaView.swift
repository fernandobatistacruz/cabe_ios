//
//  TransferenciaView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 14/01/26.
//

import SwiftUI

struct TransferenciaView: View {

    @StateObject private var vm: TransferenciaViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Init

    init() {
        let useCase = TransferenciaUseCase()
        _vm = StateObject(
            wrappedValue: TransferenciaViewModel(useCase: useCase)
        )
    }

    // MARK: - Body

    var body: some View {
        Form {

            // 🔹 Conta origem
            Section("Conta de Origem") {
                Picker("Selecione", selection: $vm.contaOrigemUuid) {
                    Text("Selecione")
                        .tag(String?.none)

                    ForEach(vm.contas) { conta in
                        Text(conta.nome)
                            .tag(Optional(conta.uuid))
                    }
                }
            }

            // 🔹 Conta destino
            Section("Conta de Destino") {
                Picker("Selecione", selection: $vm.contaDestinoUuid) {
                    Text("Selecione")
                        .tag(String?.none)

                    ForEach(vm.contas) { conta in
                        Text(conta.nome)
                            .tag(Optional(conta.uuid))
                    }
                }
            }

            // 🔹 Valor
            // 🔹 Valor
            Section("Valor") {
                TextField(
                    NSLocalizedString("transfer.value.placeholder", comment: "Valor da transferência"),
                    text: $vm.valorTexto
                )
                .keyboardType(.numberPad)
                .onChange(of: vm.valorTexto) { novoValor in
                    vm.atualizarValor(novoValor)
                }
            }           
        }
        .navigationTitle("Transferência")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    do {
                        try vm.transferir()
                        dismiss()
                    } catch {
                        // futuramente: alert
                        print("Erro na transferência:", error)
                    }
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                    
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .disabled(!podeTransferir)
            }
           
        }
        
    }

    // MARK: - Helpers
    
    private var podeTransferir: Bool {
            vm.contaOrigemUuid != nil &&
            vm.contaDestinoUuid != nil &&
            vm.contaOrigemUuid != vm.contaDestinoUuid &&
            vm.valor > 0
        }

    private var formularioValido: Bool {
        vm.contaOrigemUuid != nil &&
        vm.contaDestinoUuid != nil &&
        vm.contaOrigemUuid != vm.contaDestinoUuid &&
        vm.valor > 0
    }

    private func executarTransferencia() {
        do {
            try vm.transferir()
            dismiss()
        } catch {
            print("Erro ao transferir:", error)
        }
    }
}
