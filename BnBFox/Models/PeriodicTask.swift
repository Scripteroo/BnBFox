//
//  PeriodicTask.swift
//  BnBFox
//
//  Model for recurring maintenance tasks
//

import Foundation

enum TaskFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case semiAnnually = "Semi-annually"
    case annually = "Annually"
    
    var days: Int {
        switch self {
        case .weekly: return 7
        case .monthly: return 30
        case .quarterly: return 90
        case .semiAnnually: return 182
        case .annually: return 365
        }
    }
}

enum TaskScope: String, Codable {
    case global = "All Properties"
    case propertySpecific = "Specific Property"
}

struct PeriodicTask: Identifiable, Codable {
    let id: UUID
    var name: String
    var frequency: TaskFrequency
    var scope: TaskScope
    var propertyId: String? // nil if global
    var startDate: Date
    var isEnabled: Bool
    var lastCompletedDate: Date?
    var isDefault: Bool // true for AC filter, false for custom tasks
    
    init(
        id: UUID = UUID(),
        name: String,
        frequency: TaskFrequency,
        scope: TaskScope,
        propertyId: String? = nil,
        startDate: Date = Date(),
        isEnabled: Bool = true,
        lastCompletedDate: Date? = nil,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.frequency = frequency
        self.scope = scope
        self.propertyId = propertyId
        self.startDate = startDate
        self.isEnabled = isEnabled
        self.lastCompletedDate = lastCompletedDate
        self.isDefault = isDefault
    }
    
    // Check if task is due on a given date for a specific property
    func isDue(on date: Date, for propertyId: String) -> Bool {
        guard isEnabled else { return false }
        
        // Check if task applies to this property
        switch scope {
        case .global:
            break // Applies to all properties
        case .propertySpecific:
            guard self.propertyId == propertyId else { return false }
        }
        
        let calendar = Calendar.current
        
        // Check if date is after start date
        guard date >= calendar.startOfDay(for: startDate) else { return false }
        
        // If never completed, check if it's the first occurrence
        guard let lastCompleted = lastCompletedDate else {
            return isFirstOccurrence(on: date)
        }
        
        // Check if enough time has passed since last completion
        let daysSinceCompletion = calendar.dateComponents([.day], from: lastCompleted, to: date).day ?? 0
        return daysSinceCompletion >= frequency.days
    }
    
    private func isFirstOccurrence(on date: Date) -> Bool {
        let calendar = Calendar.current
        
        switch frequency {
        case .weekly:
            // Due on same day of week as start date
            let startWeekday = calendar.component(.weekday, from: startDate)
            let dateWeekday = calendar.component(.weekday, from: date)
            return startWeekday == dateWeekday && date >= startDate
            
        case .monthly:
            // Due on same day of month as start date
            let startDay = calendar.component(.day, from: startDate)
            let dateDay = calendar.component(.day, from: date)
            return startDay == dateDay && date >= startDate
            
        case .quarterly:
            // Due on first day of quarter (Jan 1, Apr 1, Jul 1, Oct 1)
            let month = calendar.component(.month, from: date)
            let day = calendar.component(.day, from: date)
            return (month == 1 || month == 4 || month == 7 || month == 10) && day == 1
            
        case .semiAnnually:
            // Due on first day of half-year (Jan 1, Jul 1)
            let month = calendar.component(.month, from: date)
            let day = calendar.component(.day, from: date)
            return (month == 1 || month == 7) && day == 1
            
        case .annually:
            // Due on anniversary of start date
            let startMonth = calendar.component(.month, from: startDate)
            let startDay = calendar.component(.day, from: startDate)
            let dateMonth = calendar.component(.month, from: date)
            let dateDay = calendar.component(.day, from: date)
            return startMonth == dateMonth && startDay == dateDay && date >= startDate
        }
    }
    
    // Get display text for the task
    var displayText: String {
        switch frequency {
        case .quarterly:
            return "🌬️ \(name) (Quarterly)"
        case .monthly:
            return "📅 \(name) (Monthly)"
        case .weekly:
            return "🔄 \(name) (Weekly)"
        case .semiAnnually:
            return "📆 \(name) (Semi-annually)"
        case .annually:
            return "🗓️ \(name) (Annually)"
        }
    }
}

// Service to manage periodic tasks
class PeriodicTaskService: ObservableObject {
    static let shared = PeriodicTaskService()
    
    @Published var tasks: [PeriodicTask] = []
    
    private let tasksKey = "periodicTasks"
    
    private init() {
        loadTasks()
        createDefaultACFilterTask()
    }
    
    private func createDefaultACFilterTask() {
        // Check if AC filter task already exists
        if !tasks.contains(where: { $0.isDefault && $0.name == "Change AC Filter" }) {
            let acFilterTask = PeriodicTask(
                name: "Change AC Filter",
                frequency: .quarterly,
                scope: .global,
                startDate: getNextQuarterStart(),
                isEnabled: true,
                isDefault: true
            )
            tasks.append(acFilterTask)
            saveTasks()
        }
    }
    
    private func getNextQuarterStart() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        
        var targetMonth: Int
        if currentMonth < 4 {
            targetMonth = 4
        } else if currentMonth < 7 {
            targetMonth = 7
        } else if currentMonth < 10 {
            targetMonth = 10
        } else {
            targetMonth = 1 // Next year
        }
        
        var components = calendar.dateComponents([.year], from: now)
        if targetMonth == 1, let year = components.year {
            components.year = year + 1
        }
        components.month = targetMonth
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        return calendar.date(from: components) ?? now
    }
    
    func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([PeriodicTask].self, from: data) {
            tasks = decoded
        }
    }
    
    func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: tasksKey)
        }
        objectWillChange.send()
    }
    
    func addTask(_ task: PeriodicTask) {
        tasks.append(task)
        saveTasks()
    }
    
    func updateTask(_ task: PeriodicTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
        }
    }
    
    func deleteTask(_ task: PeriodicTask) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    func getTasksDue(on date: Date, for propertyId: String) -> [PeriodicTask] {
        return tasks.filter { $0.isDue(on: date, for: propertyId) }
    }
    
    func markTaskCompleted(_ task: PeriodicTask, on date: Date) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].lastCompletedDate = date
            saveTasks()
        }
    }
}
