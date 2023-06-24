//
//  ContentView.swift
//  BetterRestIOS
//
//  Created by Ver Pasamic on 6/24/23.
//

import SwiftUI
import CoreML

struct ContentView: View {
    static var defaultWakeTime: Date {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    @State private var sleepAmount = 8.0
    @State private var coffeeAmount = 1
    @State private var teaAmount = 1
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

                Section(header: Text("Coffee Intake").font(.headline)) {
                    Picker("Coffee cups", selection: $coffeeAmount) {
                        ForEach(beverageAmounts, id: \.self) { amount in
                            Text("\(amount) cup\(amount > 1 ? "s" : "")")
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 100)
                }
                
                Section(header: Text("Tea Intake").font(.headline)) {
                    Picker("Tea cups", selection: $teaAmount) {
                        ForEach(beverageAmounts, id: \.self) { amount in
                            Text("\(amount) cup\(amount > 1 ? "s" : "")")
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

        let coffeeMultiplier = 1.0
        let teaMultiplier = 1.0 / 3.0

        let adjustedCoffeeAmount = Double(coffeeAmount) * coffeeMultiplier
        let adjustedTeaAmount = Double(teaAmount) * teaMultiplier

        let totalBeverageAmount = adjustedCoffeeAmount + adjustedTeaAmount

        do {
            let config = MLModelConfiguration()
            let model = try SleepCalculator(configuration: config)

            let prediction = try model.prediction(wake: Double(hour + minute), estimatedSleep: sleepAmount, coffee: totalBeverageAmount)

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
