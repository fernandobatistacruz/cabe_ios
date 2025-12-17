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
                VStack(spacing: 16) {

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

                        NavigationLink {
                            Text("Selecionar Categoria")
                        } label: {
                            HStack {
                                Text("Categoria")
                                Spacer()
                                Text(categoria.isEmpty ? "Categoria" : categoria)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                        }
                    }
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Pago Com")
                                Text("Cartão")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(pagoCom)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()

                        Divider()

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

                        Toggle("Dividida", isOn: $dividida)
                            .padding()

                        Divider()

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

                        TextField("Valor", text: $valor)
                            .keyboardType(.decimalPad)
                            .padding()
                        
                        Divider()

                        Toggle("Pago", isOn: $pago)
                            .padding()

                        Divider()

                        DatePicker(selection: $dataCompra, displayedComponents: .date) {
                            HStack {
                                Text("Data da Compra")
                                Spacer()
                                Text(dataCompra.formatted(date: .numeric, time: .omitted))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .datePickerStyle(.wheel)
                        .padding(.vertical)

                     
                    }
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    VStack {
                        TextField("Anotação", text: $anotacao, axis: .vertical)
                            .lineLimit(4...6)
                            .padding()
                    }
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(uiColor: .systemGroupedBackground))
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
                    }                   
                    
                }
            }
        }
    }
}

#Preview {
    NovaDespesaView()
}
