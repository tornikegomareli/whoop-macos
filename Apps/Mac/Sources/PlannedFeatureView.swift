import SwiftUI

struct PlannedFeatureView: View {
    let destination: AppDestination

    var body: some View {
        ContentUnavailableView {
            Label(destination.title, systemImage: destination.symbol)
        } description: {
            Text("This area is part of the next WhoopScope milestone.")
        }
        .navigationTitle(destination.title)
    }
}

