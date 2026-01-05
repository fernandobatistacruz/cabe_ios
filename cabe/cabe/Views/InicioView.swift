//
//  InicioView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 12/12/25.
//

import SwiftUI
internal import Combine
import GRDB

struct InicioView: View {
    @State private var mostrarNovaDespesa = false
    @State private var showCalendar = false
    @StateObject private var vm = NotificacoesViewModel()
    @StateObject private var viewModel: LancamentoListViewModel
    
    private var selectedDate: Date {
        Calendar.current.date(
            from: DateComponents(
                year: viewModel.anoAtual,
                month: viewModel.mesAtual,
                day: 1
            )
        ) ?? Date()
    }
    
    init() {
        let repository = LancamentoRepository()
        let mesAtual = Calendar.current.component(.month, from: Date())
        let anoAtual = Calendar.current.component(.year, from: Date())
        
        _viewModel = StateObject(
            wrappedValue: LancamentoListViewModel(
                repository: repository,
                mes: mesAtual,
                ano: anoAtual
            )
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        FavoritosView(
                            balanco: viewModel.balanco,
                            cartao: viewModel.totalCartao,
                            despesas: viewModel.totalDespesas,
                        )
                        
                        NavigationLink {
                            ConsumoDetalhadoView(
                                vm: viewModel,
                                items: viewModel.gastosPorCategoriaDetalhado
                            )
                        } label: {
                            ConsumoCardView(
                                dados: viewModel.gastosPorCategoriaResumo
                            )
                        }
                        .buttonStyle(.plain)
                        
                        RecentesListView()
                    }
                    .padding(.bottom, 10)
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
                                .frame(width: 48, height: 48)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(
                Text(selectedDate, format: .dateTime.month(.wide))
            )
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showCalendar = true
                    } label: {
                        //Image(systemName: "chevron.left")
                        Text(selectedDate, format: .dateTime.year())
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink(
                        destination: NotificacoesView(vm: vm)
                    ) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .font(.system(size: 20))
                            
                            if vm.totalNotificacoes > 0 {
                                Text("\(vm.totalNotificacoes)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(5)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -6)
                            }
                        }
                        .frame(minWidth: 36, minHeight: 36)
                        
                    }
                    Button {
                        print("Mais")
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    
                }
            }
            .sheet(isPresented: $showCalendar) {
                CalendarioZoomView(
                    dataInicial: selectedDate,
                    onConfirm: { dataSelecionada in
                        viewModel.selecionar(data: dataSelecionada)
                    }
                )
                .presentationDetents([.medium, .large])
                
            }

        }
        .sheet(isPresented: $mostrarNovaDespesa) {
            NovoLancamentoView()
        }
    }

}

#Preview {
    //InicioView().environmentObject(ThemeManager())
}

struct FavoritosView: View{
    let balanco: Decimal
    let cartao: Decimal
    let despesas: Decimal
    
    var body: some View {
        VStack(alignment: .leading){
            
            Text("Resumo")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            HStack() {
                CardItem(
                    title: String(localized: "Balanço"),
                    value: balanco,
                    color: .purple,
                    icone:  "chart.bar.fill",
                )
                NavigationLink {
                    CartaoListView()
                } label: {
                    CardItem(
                        title: String(localized: "Cartões"),
                        value: cartao,
                        color: .orange,
                        icone: "creditcard.fill"
                    )
                }
                .buttonStyle(.plain)
            }.padding(.horizontal)
            HStack() {
                NavigationLink {                    
                    ContaListView()
                } label: {
                    CardItem(
                        title: String(localized: "Contas"),
                        value: 2500,
                        color: .blue,
                        icone:  "wallet.bifold.fill",
                    )
                }.buttonStyle(.plain)                
                CardItem(
                    title: String(localized: "Despesas"),
                    value: despesas,
                    color: .red,
                    icone: "barcode"
                    
                )
            }.padding(.horizontal)
        }
    }
}

struct CardItem: View {

    let title: String
    let value: Decimal
    let color: Color
    let icone: String
    
    // Generates a subtle vertical gradient derived from the base color
    // Keeps good contrast in light/dark mode and avoids fully opaque blocks
    private func gradientColors(from base: Color) -> [Color] {
        // Slightly vary opacity for depth while keeping the hue
        let top = base.opacity(0.32)
        let middle = base.opacity(0.25)
        let bottom = base.opacity(0.36)
        return [top, middle, bottom]
    }

    var body: some View {
        HStack() {
            Image(systemName: icone)
                .font(.title3)
                .foregroundStyle(color)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Text(value, format: .currency(code: "BRL"))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: gradientColors(from: color),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct ConsumoCardView: View {
    
    let dados: [CategoriaResumo]

    var body: some View {
        
        VStack(alignment: .leading){
            Text("Consumo")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            HStack(spacing: 24) {
                ConsumoListView(items: dados)
                    .padding()
                DonutChartView(items: dados, lineWidth: 18 , size: 70)
                    .padding(.trailing, 30)
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
