import Foundation

protocol TaskStorageProtocol{
    func loadTasks() -> [TaskProtocol]
    func saveTasks(tasks: [TaskProtocol])
}

class TaskStorage: TaskStorageProtocol{
    //Создание ссылки на хранилище
    private var storage = UserDefaults.standard
    var storageKey: String = "tasks"
    
    //Перечисление с ключами
    private enum TaskKey: String{
        case title
        case type
        case status
    }
    
    func loadTasks() -> [TaskProtocol]{
        var resultTasks: [TaskProtocol] = []
        let tasksFromStorage = storage.array(forKey: storageKey) as? [[String : String]] ?? []
        
        for task in tasksFromStorage {
            guard let title = task[TaskKey.title.rawValue],
                  let typeRaw = task[TaskKey.type.rawValue],
                  let statusRaw = task[TaskKey.status.rawValue] else {
                continue
            }
            let type: TaskPriority = typeRaw == "important" ? .important : .normal
            let status: TaskStatus = statusRaw == "planned" ? .planned : .completed
            
            resultTasks.append(Task(title: title, type: type, status: status))
        }
        return resultTasks
    }
    
    func saveTasks(tasks: [TaskProtocol]) {
        var arrayForStorage: [[String : String]] = []
        tasks.forEach{ task in
            var newElementForStorage: Dictionary<String, String> = [:]
            newElementForStorage[TaskKey.title.rawValue] = task.title
            newElementForStorage[TaskKey.type.rawValue] = (task.type == .important) ? "important" : "normal"
            newElementForStorage[TaskKey.status.rawValue] = (task.status == .completed) ? "completed" : "planned"
            arrayForStorage.append(newElementForStorage)
        }
        storage.set(arrayForStorage, forKey: storageKey)
        print("saved")
    }
    
}
