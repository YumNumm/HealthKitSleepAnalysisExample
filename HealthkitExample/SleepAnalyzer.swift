import HealthKit

public class SleepAnalyzer {
    // 睡眠判定のための閾値
    private let minSleepDuration: TimeInterval = 30 * 60  // 最小睡眠時間(30分)

    // 睡眠状態の解析結果
    public struct SleepPeriod {
        public let startTime: Date
        public let endTime: Date
        public let sleepType: HKCategoryValueSleepAnalysis

        public init(startTime: Date, endTime: Date, sleepType: HKCategoryValueSleepAnalysis) {
            self.startTime = startTime
            self.endTime = endTime
            self.sleepType = sleepType
        }
    }

    public init() {}

    public func analyzeSleepPeriods(from samples: [HKCategorySample]) -> [SleepPeriod] {
        var sleepPeriods: [SleepPeriod] = []
        var currentPeriod: (start: Date, type: HKCategoryValueSleepAnalysis)?

        // サンプルを時系列順にソート
        let sortedSamples = samples.sorted { $0.startDate < $1.startDate }

        for (index, sample) in sortedSamples.enumerated() {
            let value = HKCategoryValueSleepAnalysis(rawValue: sample.value)!

            // 新しい睡眠期間の開始
            if currentPeriod == nil {
                currentPeriod = (sample.startDate, value)
            } else {
                // 睡眠期間の終了判定（30分以上のギャップがある場合のみ）
                let isLastSample = index == sortedSamples.count - 1
                let nextSampleGap = isLastSample ? 0 :
                    sortedSamples[index + 1].startDate.timeIntervalSince(sample.endDate)

                if nextSampleGap > 30 * 60 { // 30分以上のギャップ
                    // 睡眠期間を終了して記録
                    if let period = currentPeriod {
                        let duration = sample.endDate.timeIntervalSince(period.start)
                        if duration >= minSleepDuration {
                            sleepPeriods.append(SleepPeriod(
                                startTime: period.start,
                                endTime: sample.endDate,
                                sleepType: period.type
                            ))
                        }
                    }
                    currentPeriod = nil
                }
            }
        }

        // 最後の期間を処理
        if let lastPeriod = currentPeriod, let lastSample = sortedSamples.last {
            let duration = lastSample.endDate.timeIntervalSince(lastPeriod.start)
            if duration >= minSleepDuration {
                sleepPeriods.append(SleepPeriod(
                    startTime: lastPeriod.start,
                    endTime: lastSample.endDate,
                    sleepType: lastPeriod.type
                ))
            }
        }

        return sleepPeriods
    }

    public func getSleepSummary(from periods: [SleepPeriod]) -> (sleepStart: Date?, wakeTime: Date?) {
        guard !periods.isEmpty else { return (nil, nil) }

        // 最初の睡眠開始時刻と最後の起床時刻を取得
        let sortedPeriods = periods.sorted { $0.startTime < $1.startTime }
        let sleepStart = sortedPeriods.first?.startTime
        let wakeTime = sortedPeriods.last?.endTime

        return (sleepStart, wakeTime)
    }
}
