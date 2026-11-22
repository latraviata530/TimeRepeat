import SwiftUI
import UserNotifications

@MainActor
final class TimerModel: ObservableObject {
    @Published var hours = 6
    @Published var minutes = 0
    @Published var seconds = 0
    @Published var repetitions = 4
    @Published var isRunning = false
    @Published var remaining: TimeInterval = 0
    @Published var status = "Listo para empezar"

    private var endDate: Date?
    private var ticker: Timer?

    var interval: TimeInterval {
        TimeInterval(hours * 3600 + minutes * 60 + seconds)
    }

    var formattedRemaining: String {
        let value = max(0, Int(remaining))
        return String(format: "%02d:%02d:%02d", value / 3600, (value % 3600) / 60, value % 60)
    }

    func start() {
        guard interval > 0, repetitions > 0 else {
            status = "Elige un intervalo y al menos un aviso."
            return
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                guard granted else {
                    self.status = "Activa las notificaciones de TimeRepeat en Ajustes."
                    return
                }
                self.scheduleNotifications()
                self.endDate = Date().addingTimeInterval(self.interval)
                self.remaining = self.interval
                self.isRunning = true
                self.status = "Contador en marcha"
                self.startTicker()
            }
        }
    }

    private func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: (1...64).map { "timerrepeat-\($0)" })
        let count = min(repetitions, 64) // iOS limits the number of pending local notifications per app.
        for index in 1...count {
            let content = UNMutableNotificationContent()
            content.title = "TimeRepeat"
            content.body = "Aviso \(index) de \(count): ha terminado el intervalo."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval * Double(index), repeats: false)
            let request = UNNotificationRequest(identifier: "timerrepeat-\(index)", content: content, trigger: trigger)
            center.add(request)
        }
    }

    func pause() {
        guard isRunning else { return }
        isRunning = false
        ticker?.invalidate()
        ticker = nil
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        status = "Pausado. Pulsa continuar para programar los avisos restantes."
    }

    func resume() {
        guard !isRunning, remaining > 0 else { return }
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let center = UNUserNotificationCenter.current()
        let left = max(1, Int(ceil(remaining)))
        for index in 1...min(repetitions, 64) {
            let content = UNMutableNotificationContent()
            content.title = "TimeRepeat"
            content.body = "Aviso \(index) de \(repetitions): ha terminado el intervalo."
            content.sound = .default
            let delay = TimeInterval(left) + interval * Double(index - 1)
            center.add(UNNotificationRequest(identifier: "timerrepeat-resume-\(index)", content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)))
        }
        endDate = Date().addingTimeInterval(remaining)
        isRunning = true
        status = "Contador en marcha"
        startTicker()
    }

    func cancel() {
        ticker?.invalidate()
        ticker = nil
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        isRunning = false
        remaining = 0
        endDate = nil
        status = "Cancelado"
    }

    private func startTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let endDate = self.endDate else { return }
            let left = endDate.timeIntervalSinceNow
            self.remaining = max(0, left)
            if left <= 0 {
                self.ticker?.invalidate()
                self.ticker = nil
                self.isRunning = false
                self.status = "Intervalo terminado. Revisa tus notificaciones."
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var model = TimerModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Intervalo entre avisos") {
                    Stepper("Horas: \(model.hours)", value: $model.hours, in: 0...23)
                    Stepper("Minutos: \(model.minutes)", value: $model.minutes, in: 0...59)
                    Stepper("Segundos: \(model.seconds)", value: $model.seconds, in: 0...59)
                }
                Section("Número de avisos") {
                    Stepper("Repeticiones: \(model.repetitions)", value: $model.repetitions, in: 1...64)
                    Text("Se pueden programar hasta 64 avisos por tanda.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Cuenta atrás") {
                    Text(model.formattedRemaining)
                        .font(.system(size: 42, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .frame(maxWidth: .infinity)
                    Text(model.status)
                        .font(.footnote).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                Section {
                    Button("Iniciar contador") { model.start() }
                        .disabled(model.isRunning)
                    Button("Pausar") { model.pause() }
                        .disabled(!model.isRunning)
                    Button("Continuar") { model.resume() }
                        .disabled(model.isRunning || model.remaining <= 0)
                    Button("Cancelar", role: .destructive) { model.cancel() }
                }
            }
            .navigationTitle("TimeRepeat")
        }
    }
}
