import UIKit
import UserNotifications
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Register background task first, before anything else
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.decaff.dailySummary",
            using: nil
        ) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        // Then set up notifications
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule a new background task
        scheduleAppRefresh()
        
        // Create a task to update the notification content
        let updateTask = Task {
            do {
                // Get today's entries and generate new summary
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: Date())
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                
                // Note: You'll need to implement a way to access entries here
                // This is just a placeholder
                let todayEntries: [CaffeineEntry] = []
                
                let summary = try await GPTService.shared.generateDailySummary(caffeineEntries: todayEntries)
                
                // Update notification content
                let content = UNMutableNotificationContent()
                content.title = "Daily Caffeine Summary"
                content.body = summary
                
                // Schedule the notification
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: calendar.dateComponents([.hour, .minute], from: Date()),
                    repeats: true
                )
                
                let request = UNNotificationRequest(
                    identifier: "dailySummary",
                    content: content,
                    trigger: trigger
                )
                
                try await UNUserNotificationCenter.current().add(request)
                task.setTaskCompleted(success: true)
            } catch {
                print("Background task failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
        
        // Ensure the task is cancelled if the background time runs out
        task.expirationHandler = {
            updateTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
    
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.decaff.dailySummary")
        request.earliestBeginDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
} 