//
//  SleepChartView.swift
//  HealthkitExample
//

import SwiftUI
import HealthKit
import Charts

public struct SleepChartView: View {
    var sleepData: [HKCategorySample]
    @State private var remSleepSeconds: TimeInterval = 0
    @State private var deepSleepSeconds: TimeInterval = 0
    @State private var coreSleepSeconds: TimeInterval = 0
    @State private var awakeSeconds: TimeInterval = 0
    @State private var inBedSeconds: TimeInterval = 0
    @State private var awakeningsCount: Int = 0
    @State private var sleepStart: Date?
    @State private var wakeTime: Date?

    private let sleepAnalyzer = SleepAnalyzer()
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        return String(format: "%02d:%02d", hours, minutes)
    }

    public init(sleepData: [HKCategorySample]) {
        self.sleepData = sleepData
    }

    public var body: some View {
        VStack(spacing: 20) {
            // 睡眠開始・終了時刻
            if let sleepStart = sleepStart, let wakeTime = wakeTime {
                HStack(spacing: 20) {
                    VStack {
                        Text("Sleep Time")
                            .font(.caption)
                        Text(timeFormatter.string(from: sleepStart))
                            .font(.title3)
                            .bold()
                    }

                    VStack {
                        Text("Wake Time")
                            .font(.caption)
                        Text(timeFormatter.string(from: wakeTime))
                            .font(.title3)
                            .bold()
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }

            // 睡眠タイプごとの時間を表示
            HStack(spacing: 15) {
                SleepTypeCard(title: "In Bed",
                             hours: inBedSeconds / 3600,
                             duration: formatDuration(inBedSeconds),
                             color: .gray)
            }
            .padding(.bottom, 5)

            HStack(spacing: 15) {
                SleepTypeCard(title: "REM",
                             hours: remSleepSeconds / 3600,
                             duration: formatDuration(remSleepSeconds),
                             color: .blue)

                SleepTypeCard(title: "Deep",
                             hours: deepSleepSeconds / 3600,
                             duration: formatDuration(deepSleepSeconds),
                             color: .purple)

                SleepTypeCard(title: "Core",
                             hours: coreSleepSeconds / 3600,
                             duration: formatDuration(coreSleepSeconds),
                             color: .green)

                SleepTypeCard(title: "Awake",
                             hours: awakeSeconds / 3600,
                             duration: formatDuration(awakeSeconds),
                             color: .orange)
            }
            .padding()

            // 睡眠効率の計算（覚醒時間を除外）
            if inBedSeconds > 0 {
                let totalSleepSeconds = remSleepSeconds + deepSleepSeconds + coreSleepSeconds
                let efficiency = (totalSleepSeconds / inBedSeconds) * 100
                VStack {
                    Text("Sleep Efficiency")
                        .font(.headline)
                    Text(String(format: "%.1f%%", efficiency))
                        .font(.title2)
                        .bold()
                        .foregroundColor(efficiencyColor(efficiency))
                }
                .padding(.vertical, 5)
            }

            // 総睡眠時間（覚醒時間を除外）
            VStack {
                Text("Total Sleep")
                    .font(.headline)
                let totalSeconds = remSleepSeconds + deepSleepSeconds + coreSleepSeconds
                VStack(spacing: 5) {
                    Text(String(format: "%.1f hrs", totalSeconds / 3600))
                        .font(.title)
                        .bold()
                    Text(formatDuration(totalSeconds))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // 目覚めた回数
            Text("Awakenings: \(awakeningsCount)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .onAppear {
            processSleepData()
        }
    }

    private func processSleepData() {
        remSleepSeconds = 0
        deepSleepSeconds = 0
        coreSleepSeconds = 0
        awakeSeconds = 0
        inBedSeconds = 0
        awakeningsCount = 0

        // Apple Healthからのデータのみをフィルタリング
        let filteredSamples = sleepData.filter { sample in
            let source = sample.sourceRevision.source.bundleIdentifier
            return source.starts(with: "com.apple.health")
        }

        // 各睡眠タイプの時間を計算
        for sample in filteredSamples {
            let value = sample.value
            let duration = sample.endDate.timeIntervalSince(sample.startDate)

            switch value {
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                remSleepSeconds += duration
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                coreSleepSeconds += duration
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                deepSleepSeconds += duration
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                inBedSeconds += duration
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                awakeSeconds += duration
                awakeningsCount += 1
            default:
                break
            }
        }

        // 睡眠期間の解析を追加
        let periods = sleepAnalyzer.analyzeSleepPeriods(from: sleepData)
        let summary = sleepAnalyzer.getSleepSummary(from: periods)
        sleepStart = summary.sleepStart
        wakeTime = summary.wakeTime
    }

    private func efficiencyColor(_ efficiency: Double) -> Color {
        switch efficiency {
        case 0..<65:
            return .red
        case 65..<80:
            return .orange
        case 80..<90:
            return .blue
        default:
            return .green
        }
    }
}

// 睡眠タイプごとのカードビュー
struct SleepTypeCard: View {
    let title: String
    let hours: Double
    let duration: String
    let color: Color

    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(String(format: "%.1f", hours))
                .font(.title3)
                .bold()
            Text("hrs")
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(duration)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}
