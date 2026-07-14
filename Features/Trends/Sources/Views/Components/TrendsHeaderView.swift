import SwiftUI
import WhoopScopeDomain

struct TrendsHeaderView: View {
    let snapshot: TrendsSnapshot
    let selectedRange: TrendRange
    let isRefreshing: Bool
    let selectRange: (TrendRange) -> Void
    let refresh: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your trends")
                    .font(.largeTitle.bold())

                Text(
                    "\(snapshot.startDate.formatted(.dateTime.month(.abbreviated).day()))–\(snapshot.endDate.formatted(.dateTime.month(.abbreviated).day().year())) · Updated \(snapshot.lastSynchronizedAt, style: .relative)"
                )
                .font(.callout)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Picker("Time range", selection: rangeBinding) {
                ForEach(TrendRange.allCases) { range in
                    Text(range.shortTitle).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 220)
            .accessibilityHint("Changes the period used by every trend and comparison")

            Button("Refresh", systemImage: "arrow.clockwise", action: refresh)
                .disabled(isRefreshing)
        }
    }

    private var rangeBinding: Binding<TrendRange> {
        Binding(
            get: { selectedRange },
            set: { range in selectRange(range) }
        )
    }
}
