import SwiftUI

struct CalendarioZoomView: View {

    let dataInicial: Date
    let onConfirm: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var dataSelecionada: Date

    init(
        dataInicial: Date,
        onConfirm: @escaping (Date) -> Void
    ) {
        self.dataInicial = dataInicial
        self.onConfirm = onConfirm
        _dataSelecionada = State(initialValue: dataInicial)
    }

    private let calendar = Calendar.current

    private let years: [Int] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(2020...(currentYear + 10))
    }()

    // MARK: - Computed
    private var selectedYear: Int {
        calendar.component(.year, from: dataSelecionada)
    }

    private var selectedMonth: Int {
        calendar.component(.month, from: dataSelecionada)
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            mainContent
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    leadingToolbar
                    trailingToolbar
                }
        }
    }
}

private extension CalendarioZoomView {

    var mainContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 32) {
                    Color.clear.frame(height: 12)
                    yearsList
                    Color.clear.frame(height: 24)
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(selectedYear, anchor: .center)
                }
            }
        }
    }

    var yearsList: some View {
        ForEach(years, id: \.self) { year in
            yearSection(for: year)
                .id(year)
        }
    }

    func yearSection(for year: Int) -> some View {
        YearSection(
            year: year,
            calendar: calendar,
            selectedYear: selectedYear,
            selectedMonth: selectedMonth,
            onSelect: handleMonthSelection
        )
    }

    var leadingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
        }
    }

    var trailingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Hoje") {
                selectToday()
            }
            .fontWeight(.semibold)
        }
    }
}

private extension CalendarioZoomView {

    func handleMonthSelection(year: Int, month: Int) {
        let date = calendar.date(
            from: DateComponents(year: year, month: month, day: 1)
        ) ?? dataSelecionada

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            dataSelecionada = date
        }

        onConfirm(date)
        dismiss()
    }

    func selectToday() {
        let today = calendar.startOfDay(for: Date())
        dataSelecionada = today

        onConfirm(today)
        dismiss()
    }
}

struct YearSection: View {

    let year: Int
    let calendar: Calendar
    let selectedYear: Int
    let selectedMonth: Int
    let onSelect: (Int, Int) -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 12),
        count: 3
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text(year, format: .number.grouping(.never))
                .font(.title.weight(.semibold))
                .foregroundColor(year == selectedYear ? .accentColor : .primary)
                .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(1...12, id: \.self) { month in
                    MonthCell(
                        title: calendar.monthSymbols[month - 1],
                        isSelected: year == selectedYear && month == selectedMonth
                    )
                    .onTapGesture {
                        onSelect(year, month)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct MonthCell: View {

    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title.capitalized)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity, minHeight: 35)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        isSelected ? Color.accentColor : Color.secondary.opacity(0.10)
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

#Preview {
   
   
}

struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    let content: (Binding<Value>) -> Content

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}

