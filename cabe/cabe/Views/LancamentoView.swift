//
//  LancamentoCadastrarView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 16/12/25.
//

import SwiftUI

struct NovaDespesaView: View {
    enum Tipo {
        case despesa, receita
    }

    @Environment(\.dismiss) private var dismiss

    @State private var tipo: Tipo = .despesa
    @State private var descricao: String = ""
    @State private var categoria: String = ""

    @State private var pagoCom: String = "Smiles Nosso"
    @State private var fatura: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()

    @State private var dividida: Bool = false
    @State private var repete: String = "Nunca"

    @State private var valor: String = ""
    @State private var dataCompra: Date = Date()

    @State private var pago: Bool = false
    @State private var anotacao: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Picker("", selection: $tipo) {
                        Text("Despesa").tag(Tipo.despesa)
                        Text("Receita").tag(Tipo.receita)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    VStack(spacing: 0) {
                        TextField("Descrição", text: $descricao)
                            .padding()
                        Divider()
                            .padding(.horizontal)
                        NavigationLink {
                            Text("Selecionar Categoria")
                        } label: {
                            HStack {
                                Text("Categoria")
                                    .tint(.secondary)
                                Spacer()
                                Text(categoria.isEmpty ? "Nenhuma" : categoria)
                                    .tint(.secondary)
                                
                                Image(systemName: "chevron.right")
                                    .tint(.secondary)
                                   
                            }
                            .padding()
                        }
                    }
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .padding(.horizontal)

                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Pago Com")
                            }
                            Spacer()
                            Text(pagoCom)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                       .padding()

                        Divider()
                            .padding(.horizontal)

                        HStack {
                            Text("Fatura")
                            Spacer()
                            Text(fatura.formatted(.dateTime.month(.wide).year()))
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()

                        Divider()
                            .padding(.horizontal)

                        Toggle("Dividida", isOn: $dividida)
                            .padding()

                        Divider()
                            .padding(.horizontal)

                        HStack {
                            Text("Repete")
                            Spacer()
                            Text(repete)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.up.chevron.down")
                                .foregroundStyle(.secondary)
                        }
                        .padding()

                        Divider()
                            .padding(.horizontal)

                        TextField("Valor", text: $valor)
                            .keyboardType(.decimalPad)
                            .padding()
                        
                        Divider()
                            .padding(.horizontal)

                        Toggle("Pago", isOn: $pago)
                           .padding()
                    }
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .padding(.horizontal)

                    VStack() {
                        TextField("Anotação", text: $anotacao, axis: .vertical)
                            .lineLimit(4...6)
                            .padding()
                    }
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .padding(.horizontal)
                }
            }
            .background(Color(uiColor: .secondarySystemBackground))
            .navigationTitle("Nova")
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
                        // salvar
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .disabled(descricao.isEmpty || valor.isEmpty)
                    
                }
            }
        }
    }
}

#Preview {
    NovaDespesaView()
}
