//
//  ContentView.swift
//  BetterRestIOS
//
//  Created by Ver Pasamic on 6/24/23.
//

import SwiftUI
import CoreML

enum BeverageType {
    case coffee
    case tea
}

struct ContentView: View {
    static var defaultWakeTime: Date {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    @State private var sleepAmount = 8.0
    @State private var beverageType = BeverageType.coffee
    @State private var beverageAmount = 1
    @State private var wakeUp = defaultWakeTime

    @State private var alertTitle = "Welcome!"
    @State private var alertMessage = "Find your best rest."
    @State private var showingAlert = false

    let beverageAmounts = Array(0...20)

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("When do you want to wake up?").font(.headline)) {
                    DatePicker("Please enter a time", selection: $wakeUp, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }

                Section(header: Text("Desired amount of sleep").font(.headline)) {
                    Stepper("\(sleepAmount.formatted()) hours", value: $sleepAmount, in: 4...12, step: 0.25)
                }

                Section(header: Text("Beverage Type").font(.headline)) {
                    Picker("Type", selection: $beverageType) {
                        Text("Coffee").tag(BeverageType.coffee)
                        Text("Tea").tag(BeverageType.tea)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Daily beverage intake").font(.headline)) {
                    Picker("Number of cups", selection: $beverageAmount) {
                        ForEach(beverageAmounts, id: \.self) { amount in
                            Text("\(amount)")
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 100)

                }
                Section(header: Text("Recommended Bedtime").font(.headline)) {
                    Text(calculateBedtime())
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .center) // Align center
                }
            }
            .navigationBarTitle("BetterRest")
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                showingAlert = true
            }
        }
    }

    func calculateBedtime() -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: wakeUp)
        let hour = (components.hour ?? 0) * 60 * 60
        let minute = (components.minute ?? 0) * 60

        let beverageMultiplier: Double
        switch beverageType {
        case .coffee:
            beverageMultiplier = 1.0
        case .tea:
            beverageMultiplier = 1.0 / 3.0
        }

        let adjustedBeverageAmount = Double(beverageAmount) * beverageMultiplier

        do {
            let config = MLModelConfiguration()
            let model = try SleepCalculator(configuration: config)

            let prediction = try model.prediction(wake: Double(hour + minute), estimatedSleep: sleepAmount, coffee: adjustedBeverageAmount)

            let sleepTime = wakeUp - prediction.actualSleep

            alertTitle = "Your ideal bedtime is…"
            alertMessage = sleepTime.formatted(date: .omitted, time: .shortened)

            return sleepTime.formatted(date: .omitted, time: .shortened)
        } catch {
            alertTitle = "Error"
            alertMessage = "Sorry, there was a problem calculating your bedtime."
            return ""
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
