import SwiftUI
import WhoopScopeDomain

struct DashboardHeaderView: View {
    let snapshot: DashboardSnapshot
    let isRefreshing: Bool
    let refresh: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Good morning, \(snapshot.displayName)")
                    .font(.largeTitle)
                    .bold()

                Text(snapshot.date, format: .dateTime.weekday(.wide).month(.wide).day())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Button(
                    isRefreshing ? "Refreshing" : "Refresh",
                    systemImage: "arrow.clockwise",
                    action: refresh
                )
                .disabled(isRefreshing)

                Text("Updated \(snapshot.lastSynchronizedAt, style: .relative)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

