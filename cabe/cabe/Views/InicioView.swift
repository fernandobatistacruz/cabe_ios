//
//  InicioView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 12/12/25.
//

import SwiftUI
internal import Combine

struct InicioView: View {
    @State private var mostrarNovaDespesa = false
    @State private var showCalendar = false
    @State public var selectedYear = Calendar.current.component(.year, from: Date())
    @State public var selectedMonth = Calendar.current.component(.month, from: Date())
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
               
                ScrollView {
                    LazyVStack(spacing: 24) {
                        FavoritosView()
                        ConsumoResumoView()
                        RecentesListView()
                    }
                    .padding(.bottom, 100) // 👈 espaço pro FAB
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()

                        Button {
                            mostrarNovaDespesa = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                                .shadow(radius: 6)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(
                Calendar.current.monthSymbols[selectedMonth - 1].capitalized
            )
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showCalendar = true
                    } label: {
                        Image(systemName: "chevron.left")
                        Text(selectedYear, format: .number.grouping(.never))
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {

                    Button {
                        print("Mais")
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }.sheet(isPresented: $showCalendar) {
                MonthYearPickerView(
                    initialYear: selectedYear,
                    initialMonth: selectedMonth
                ) { newYear, newMonth in
                    selectedYear = newYear
                    selectedMonth = newMonth
                }
                .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $mostrarNovaDespesa) {
            NovaDespesaView()
        }
    }

}

#Preview {
    InicioView().environmentObject(ThemeManager())
}

struct FavoritosView: View{
    var body: some View {
        VStack(alignment: .leading){
            
            Text("Favoritos")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                CardItem(
                    title: String(localized: "Balanço"),
                    value: "2.500,00",
                    color: Color.purple,
                    icone:  "chart.bar.fill",
                )
                NavigationLink {
                    CartoesView()
                } label: {
                    CardItem(
                        title: String(localized: "Cartões"),
                        value: "3.500,00",
                        color: .orange,
                        icone: "creditcard.fill"
                    )
                }
                .buttonStyle(.plain)
                
            }.padding(.horizontal)
            
            HStack(spacing: 12) {
                CardItem(
                    title: String(localized: "Contas"),
                    value: "2.500,00",
                    color: Color.blue,
                    icone:  "wallet.bifold.fill",
                )
                CardItem(
                    title: String(localized: "Despesas"),
                    value: "3.500,00",
                    color: Color.red,
                    icone: "barcode"
                    
                )
            }.padding(.horizontal)
        }
    }
}

struct CardItem: View {

    let title: String
    let value: String
    let color: Color
    let icone: String
    
    var body: some View {
        HStack() {
            Image(systemName: icone)
                .font(.title3)
                .foregroundStyle(color)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(color.opacity(0.15)))
        )
    }
}

struct ConsumoItem: Identifiable {
    let id = UUID()
    let nome: String
    let valor: Double
    let cor: Color
}

struct DonutChartView: View {

    let items: [ConsumoItem]
    let lineWidth: CGFloat = 18

    private var total: Double {
        items.map(\.valor).reduce(0, +)
    }

    var body: some View {
        ZStack {
            ForEach(items.indices, id: \.self) { index in
                Circle()
                    .trim(
                        from: startAngle(for: index),
                        to: endAngle(for: index)
                    )
                    .stroke(
                        items[index].cor,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .padding()
            }
        }
        .frame(width: 100, height: 100)
       
    }

    private func startAngle(for index: Int) -> CGFloat {
        let sum = items.prefix(index).map(\.valor).reduce(0, +)
        return CGFloat(sum / total)
    }

    private func endAngle(for index: Int) -> CGFloat {
        let sum = items.prefix(index + 1).map(\.valor).reduce(0, +)
        return CGFloat(sum / total)
    }
}

struct ConsumoListView: View {

    let items: [ConsumoItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(items) { item in
                HStack {
                    Circle()
                        .fill(item.cor)
                        .frame(width: 10, height: 10)

                    Text(item.nome)

                    Spacer()

                    Text("\(Int(item.valor))%")
                        .font(.body)
                        .foregroundStyle(.gray)
                }
            }
        }
    }
}

struct ConsumoResumoView: View {

    let dados: [ConsumoItem] = [
        .init(nome: "Alimentação", valor: 40, cor: .purple.opacity(0.8)),
        .init(nome: "Transporte", valor: 30, cor: .blue.opacity(0.8)),
        .init(nome: "Lazer", valor: 20, cor: .green.opacity(0.8))
    ]

    var body: some View {
        
        VStack(alignment: .leading){
            Text("Consumo")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            HStack(spacing: 24) {
                ConsumoListView(items: dados)
                    .padding()
                DonutChartView(items: dados)
                    .padding(.horizontal)
                
            }
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .padding(.horizontal)
        }
    }
}

struct RecenteItem: Identifiable {
    let id = UUID()
    let descricao: String
    let valor: Double
    let data: Date
    let icone: String
}

final class RecentesViewModel: ObservableObject {
  
    @Published var grupos: [(data: Date, itens: [RecenteItem])] = []

    init() {
        carregarDados()
    }

    private func carregarDados() {
        let lista = [
            RecenteItem(descricao: "Supermercado", valor: -120, data: Date(), icone: "cart"),
            RecenteItem(descricao: "Uber", valor: -25, data: Date(), icone: "car"),
            RecenteItem(descricao: "Salário", valor: 3500, data: Date().addingTimeInterval(-86400), icone: "banknote"),
            RecenteItem(
                descricao: "Cinema",
                valor: -120,
                data: Date().addingTimeInterval(-10110000),
                icone: "star"
            ),
            RecenteItem(
                descricao: "Viagem",
                valor: -120,
                data: Date().addingTimeInterval(-10110000),
                icone: "airplane"
            ),
        ]

        let agrupado = Dictionary(grouping: lista) {
            Calendar.current.startOfDay(for: $0.data)
        }

        grupos = agrupado
            .map { ($0.key, $0.value) }
            .sorted { $0.0 > $1.0 }
    }
}

struct RecenteRow: View {

    let item: RecenteItem

    var body: some View {
        HStack(spacing: 12) {

            Image(systemName: item.icone)
                .font(.title3)
                .foregroundStyle(.tint)

            VStack(alignment: .leading) {
                Text(item.descricao)
                Text(item.data, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(item.valor, format: .currency(code: "BRL"))
                .foregroundStyle(.gray)
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
    }
}

struct RecentesListView: View {

    @StateObject private var viewModel = RecentesViewModel()

    var body: some View {
        LazyVStack(alignment: .leading) {

            ForEach(viewModel.grupos, id: \.data) { grupo in
               
                Text(grupo.data, format: .dateTime.day().month().year())
                    .foregroundStyle(.secondary)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.top, viewModel.grupos.first?.data == grupo.data ? 0 : 10)
              
                VStack() {
                    ForEach(grupo.itens) { item in
                        
                        RecenteRow(item: item)

                        if item.id != grupo.itens.last?.id {
                            Divider()
                                .padding(.leading, 40)
                        }
                    }
                }
                .padding(10)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }.padding(.horizontal)
    }
}



#Preview {
    RecentesListView().environmentObject(ThemeManager())
}
















