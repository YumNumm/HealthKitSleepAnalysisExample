//
//  SleepListView.swift
//  HealthkitExample
//

import SwiftUI
import HealthKit

public struct SleepListView: View {
    var sleepData: [HKCategorySample]

    public init(sleepData: [HKCategorySample]) {
        self.sleepData = sleepData
    }

    public var body: some View {
        NavigationView {
            List {
                ForEach(sleepData, id: \.uuid) { sample in
                    VStack(alignment: .leading) {
                        Text(sleepTypeString(for: sample.value))
                            .font(.headline)

                        Text("Start: \(formatDate(sample.startDate))")
                            .font(.subheadline)

                        Text("End: \(formatDate(sample.endDate))")
                            .font(.subheadline)

                        Text(String(format: "Duration: %.1f hours",
                             sample.endDate.timeIntervalSince(sample.startDate) / 3600))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Sleep Records")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func sleepTypeString(for value: Int) -> String {
        switch value {
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
            return "REM Sleep"
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
            return "Core Sleep"
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
            return "Deep Sleep"
        case HKCategoryValueSleepAnalysis.awake.rawValue:
            return "Awake"
        default:
            return "Unknown"
        }
    }
}
