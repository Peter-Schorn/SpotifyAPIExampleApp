//
//  DateRangeSegmentedView.swift
//  Topotify
//
//  Created by Usama Fouad on 23/07/2022.
//

import SwiftUI

struct DateRangeSegmentedView: View {
    @State private var dateRange = 1
    
    var body: some View {
        Picker("", selection: $dateRange) {
            Text("Last 4 weeks")
                .tag(0)
            Text("Last 6 months").tag(1)
            Text("All time").tag(2)
        }
        .pickerStyle(.segmented)
        .textCase(.none)
        .scaledToFill()
        .font(.system(size: 500))
        .minimumScaleFactor(0.5)
        .lineLimit(1)
    }
}

struct dateRangeSegmentedView_Previews: PreviewProvider {
    static var previews: some View {
        DateRangeSegmentedView()
    }
}
