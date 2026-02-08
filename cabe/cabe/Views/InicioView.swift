//
//  InicioView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 12/12/25.
//

import SwiftUI
import Combine

struct InicioView: View {
    @ObservedObject var vmLancamentos: LancamentoListViewModel
    @ObservedObject var vmContas: ContaListViewModel
    @State private var mostrarNovoLancamento = false
    @State private var showCalendar = false
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    @EnvironmentObject var sub: SubscriptionManager
    @AppStorage("mostrarValores") private var mostrarValores: Bool = true
    @State private var selectedDate: Date = Date()
    @State private var direcao: Edge = .trailing
   
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 24) {
                    FavoritosView(
                        balanco: vmLancamentos.balanco,
                        cartao: vmLancamentos.totalCartao,
                        constas: vmContas.saldoTotal,
                        aVencer: vmLancamentos.totalAVencer,
                        mostrarValores: mostrarValores,
                        moeda: vmLancamentos.lancamentos.first?.currencyCode ?? Locale.systemCurrencyCode,
                        vmLancamentos: vmLancamentos
                    )
                    
                    if !sub.isSubscribed {
                        BannerView(
                            adUnitID: "ca-app-pub-1562286138930391/3659901803"
                        )
                    }
                    
                    NavigationLink {
                        ConsumoDetalhadoView(
                            vm: vmLancamentos                            
                        )
                    } label: {
                        ConsumoCardView(
                            dados: vmLancamentos.gastosPorCategoriaResumo,
                            mostrarValores: mostrarValores
                        )
                    }
                    .buttonStyle(.plain)
                    
                    RecentesListView(
                        viewModel: vmLancamentos,
                        mosttrarValores: mostrarValores
                    )

                }
                .padding(.bottom, 10)
            }           
        }
        .contentShape(Rectangle())     
        .navigationTitle(
            Text(
                selectedDate
                    .formatted(.dateTime.month(.wide))
                    .capitalized
            )
        )
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            selectedDate = Calendar.current.date(
                from: DateComponents(
                    year: vmLancamentos.anoAtual,
                    month: vmLancamentos.mesAtual,
                    day: 1
                )
            ) ?? Date()
        }
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
                Button {
                    deepLinkManager.path.append(DeepLink.notificacoes)
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                                              
                        if vmLancamentos.totalNotificacoes > 0 {
                            Text("\(vmLancamentos.totalNotificacoes)")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 6, y: -5)
                        }
                    }
                }
                Button {
                    mostrarValores.toggle()
                } label: {
                    Image(systemName: mostrarValores ? "eye.slash" : "eye" )
                }
            }
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.flexible, placement: .topBarTrailing)
            }
            ToolbarItem(placement: .topBarTrailing){
                Button {
                    mostrarNovoLancamento = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            
        }
        .sheet(isPresented: $showCalendar) {
            ZoomCalendarioView(
                dataInicial: selectedDate,
                onConfirm: { dataSelecionada in
                    selectedDate = dataSelecionada
                    showCalendar = false
                    vmLancamentos.selecionar(data: selectedDate)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $mostrarNovoLancamento) {
            NovoLancamentoView(repository: vmLancamentos.repository)
        }
        
    }
}

struct FloatingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6),
                       value: configuration.isPressed)
    }
}

struct FavoritosView: View{
    let balanco: Decimal
    let cartao: Decimal
    let constas: Decimal
    let aVencer: Decimal
    let mostrarValores: Bool
    let moeda: String
    let vmLancamentos: LancamentoListViewModel
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    
    var body: some View {
        VStack(alignment: .leading){
            
            Text("Resumo")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            HStack() {
                NavigationLink {
                    BalanceDetailView(
                        lancamentosMes: vmLancamentos.lancamentos                       
                    )
                } label: {
                    CardItem(
                        title: String(localized: "Balanço"),
                        value: balanco,
                        color: .purple,
                        icone:  "chart.bar.fill",
                        mostrarValores: mostrarValores,
                        moeda: moeda
                    )
                }
                .buttonStyle(.plain)
                NavigationLink {
                    FaturaListView(viewModel: vmLancamentos)
                } label: {
                    CardItem(
                        title: String(localized: "Cartões"),
                        value: cartao,
                        color: .orange,
                        icone: "creditcard.fill",
                        mostrarValores: mostrarValores,
                        moeda: moeda
                    )
                }
                .buttonStyle(.plain)
            }.padding(.horizontal)
            HStack() {
                NavigationLink {                    
                    ContaListView(vmLancamentos: vmLancamentos)
                } label: {
                    CardItem(
                        title: String(localized: "Contas"),
                        value: constas,
                        color: .blue,
                        icone:  "wallet.bifold.fill",
                        mostrarValores: mostrarValores,
                        moeda: moeda
                    )
                }
                .buttonStyle(.plain)
                NavigationLink {
                    LancamentoListView(
                        viewModel: vmLancamentos,
                        filtroSelecionado: .naoPagos,
                        mostrarZoomCalendario: false
                    ).toolbar(.hidden, for: .tabBar)
                } label: {
                    CardItem(
                        title: String(localized: "Em Aberto"),
                        value: -aVencer,
                        color: .cyan,
                        icone: "doc.fill",
                        mostrarValores: mostrarValores,
                        moeda: moeda
                    )
                }
                .buttonStyle(.plain)                
            }.padding(.horizontal)
        }
    }
}

struct CardItem: View {

    let title: String
    let value: Decimal
    let color: Color
    let icone: String
    let mostrarValores: Bool
    let moeda: String
    
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
        HStack(spacing: 12) {
            Image(systemName: icone)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(color)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                if(mostrarValores){
                    Text(formatarValor(value, moeda: moeda))
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundStyle(color)
                }else{
                    Text("•••")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(color)
                }
            }
            .padding(.vertical,2)
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
    
    func formatarValor(_ valor: Decimal, moeda: String) -> String {
        let locale = Locale.current

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = moeda
        formatter.locale = locale
        formatter.maximumFractionDigits = 2
        
        formatter.currencySymbol = ""
        formatter.internationalCurrencySymbol = ""
        formatter.positivePrefix = ""
        formatter.positiveSuffix = ""
        formatter.negativePrefix = "-"
        formatter.negativeSuffix = ""

        let absValor = (valor as NSDecimalNumber).doubleValue
        let numero: Decimal
        let sufixo: String

        switch absValor {
        case 1_000_000_000...:
            numero = valor / 1_000_000_000
            sufixo = NSLocalizedString("suffix_billion", comment: "")
        case 1_000_000...:
            numero = valor / 1_000_000
            sufixo = NSLocalizedString("suffix_million", comment: "")
        case 100_000...:
            numero = valor / 1_000
            sufixo = NSLocalizedString("suffix_thousand", comment: "")
        default:
            return formatter.string(from: valor as NSDecimalNumber) ?? "\(valor)"
        }

        let valorFormatado = formatter.string(from: numero as NSDecimalNumber) ?? "\(numero)"
        return "\(valorFormatado) \(sufixo)"
    }
}

struct AnimatedCounterText: View {
    let value: Decimal
    let moeda: String
    let font: Font
    let color: Color
    let formatter: (Decimal, String) -> String

    @State private var animatedValue: Decimal = .zero
    @State private var timer: Timer?

    var body: some View {
        Text(formatter(animatedValue, moeda))
            .font(font)
            .foregroundStyle(color)
            .onAppear {
                animatedValue = value
            }
            .onChange(of: value, perform: { newValue in
                animate(to: newValue)
            })
    }

    private func animate(to target: Decimal) {
        timer?.invalidate()

        let start = animatedValue
        guard start != target else { return }

        // trabalha em centavos
        let startInt = NSDecimalNumber(decimal: start * 100).intValue
        let targetInt = NSDecimalNumber(decimal: target * 100).intValue

        let distance = abs(targetInt - startInt)
        let duration: TimeInterval = 0.2
        let step = max(1, distance / 60)
        let interval = duration / Double(distance / step)

        var current = startInt

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
            if current == targetInt {
                t.invalidate()
                return
            }

            current += current < targetInt ? step : -step

            if abs(targetInt - current) < step {
                current = targetInt
            }

            animatedValue = Decimal(current) / 100
        }
    }
}

struct ConsumoCardView: View {
    
    let dados: [CategoriaResumo]
    let mostrarValores: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text("Consumo")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)

            if dados.isEmpty {
                emptyState
            } else {
                content
            }
        }
    }

    private var content: some View {
        HStack(spacing: 24) {
            ConsumoListView(items: dados, mostrarValores: mostrarValores)
                .frame(maxWidth: .infinity, minHeight: 80)
                .padding()

            DonutChartView(
                items: dados,
                lineWidth: 18,
                size: 70,
                currencyCode: dados.first?.currencyCode ?? Locale.systemCurrencyCode
            )
                .padding(.trailing, 30)
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal)
    }

    private var emptyState: some View {
        Text("Nenhum Consumo")
            .font(.headline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .padding(.horizontal)
    }
}

struct RecentesListView: View {
    
    @ObservedObject var viewModel: LancamentoListViewModel
    let mosttrarValores: Bool    
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            
            Text("Recentes")
                .font(.title3)
                .fontWeight(.semibold)                
            
            ForEach(viewModel.lancamentosRecentesAgrupadosSimples, id: \.date) { grupo in
                
                HStack{
                    Text(grupo.date, format: .dateTime.day().month(.wide))
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.top, viewModel.lancamentosRecentesAgrupadosSimples.first?.date == grupo.date ? 0 : 10)
                    
                    let total = grupo.items.reduce(.zero) { $0 + $1.valorComSinal }
                    
                    Spacer()
                    if mosttrarValores {
                        Text(total, format: .currency(code: grupo.items.first?.currencyCode ?? Locale.systemCurrencyCode))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.top, viewModel.lancamentosRecentesAgrupadosSimples.first?.date == grupo.date ? 0 : 10)
                    } else {
                        Text("•••")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.top, viewModel.lancamentosRecentesAgrupadosSimples.first?.date == grupo.date ? 0 : 10)
                    }
                }
                
                VStack(spacing: 0) {
                    ForEach(grupo.items) { lancamento in
                        HStack {
                            NavigationLink {
                                LancamentoDetalheView(
                                    lancamento: lancamento,
                                    vmLancamentos: viewModel
                                )
                            } label: {
                                LancamentoRow(
                                    lancamento: lancamento,
                                    mostrarPagamento: false,
                                    mostrarValores: mosttrarValores
                                )
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.footnote)
                        }
                        .padding(.vertical, 8)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                        if lancamento.id != grupo.items.last?.id {
                            Divider()
                                .padding(.leading, 35)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
        .padding(.horizontal)
    }
}

