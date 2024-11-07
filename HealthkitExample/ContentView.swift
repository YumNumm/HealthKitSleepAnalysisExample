//
//  ContentView.swift
//  HealthkitExample
//
//  Created by 尾上 遼太朗 on 2024/11/08.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @State private var sleepData: [HKCategorySample] = []
    @State private var selectedDate = Date()
    @State private var isDatePickerVisible = false
    @State private var isListViewPresented = false
    @State private var isAuthorized = false
    @State private var showAuthorizationView = false

    private let healthStore = HKHealthStore()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        NavigationStack {
            Group {
                if isAuthorized {
                    mainView
                } else {
                    authorizationView
                }
            }
            .navigationTitle("Sleep Analysis")
            .onAppear {
                checkHealthKitAuthorization()
            }
        }
    }

    private var mainView: some View {
        VStack {
            HStack {
                Button(action: {
                    isDatePickerVisible.toggle()
                }) {
                    HStack {
                        Text("Date: \(dateFormatter.string(from: selectedDate))")
                        Image(systemName: "calendar")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                Button(action: {
                    isListViewPresented.toggle()
                }) {
                    Text("Show Sleep List")
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()

            if sleepData.isEmpty {
                Text("No sleep data available")
            } else {
                SleepChartView(sleepData: sleepData)
            }
        }
        .padding()
        .sheet(isPresented: $isDatePickerVisible) {
            NavigationView {
                DatePicker("Select Date",
                          selection: $selectedDate,
                          displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    .navigationTitle("Select Date")
                    .navigationBarItems(
                        trailing: Button("Done") {
                            isDatePickerVisible = false
                            loadSleepData()
                        }
                    )
            }
        }
        .sheet(isPresented: $isListViewPresented) {
            SleepListView(sleepData: sleepData)
        }
    }

    private var authorizationView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("HealthKit Access Required")
                .font(.title2)
                .bold()

            Text("This app needs access to your sleep data to show your sleep analysis.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: {
                requestHealthKitAuthorization()
            }) {
                Text("Grant Access")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private func checkHealthKitAuthorization() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return
        }

        let status = healthStore.authorizationStatus(for: sleepType)

        switch status {
        case .sharingAuthorized:
            isAuthorized = true
            loadSleepData()
        case .notDetermined:
            isAuthorized = false
        default:
            isAuthorized = false
        }
    }

    private func requestHealthKitAuthorization() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return
        }

        let typesToShare: Set = [sleepType]
        let typesToRead: Set = [sleepType]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if success {
                    isAuthorized = true
                    loadSleepData()
                } else {
                    print("HealthKit authorization failed: \(String(describing: error))")
                }
            }
        }
    }

    private func loadSleepData() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return
        }

        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        // log
        print("startOfDay: \(startOfDay)")
        print("endOfDay: \(endOfDay)")

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        print("predicate: \(predicate)")
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        print("sortDescriptor: \(sortDescriptor)")

        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor]) { (query, results, error) in
            if let error = error {
                print("error: \(error)")
                print("Query Error: \(error.localizedDescription)")
                return
            }

            if let results = results as? [HKCategorySample] {
                print("results: \(results)")
                DispatchQueue.main.async {
                    self.sleepData = results
                }
            }
        }
        print("query: \(query)")

        healthStore.execute(query)
    }
}

#Preview {
    ContentView()
}
