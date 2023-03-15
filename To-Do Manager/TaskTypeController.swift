import UIKit

class TaskTypeController: UITableViewController {
    var doAfterTypeSelected: ((TaskPriority) -> Void)?
    
    // 1. Кортеж описывающий тип задачи
    typealias TypeCellDescription = (type: TaskPriority, title: String, description: String)

    // 2. Коллекция доступных типов задач с описанием
    private var taskTypesInformation: [TypeCellDescription] = [
        (type: .important, title: "Important", description: "This type of task is the highest priority to perform. All important tasks are displayed at the very top of the task list"),
        (type: .normal, title: "Normal", description: "Task with normal priority")
    ]
    
    // 3. Выбранный приоритет
    var selectedType: TaskPriority = .normal
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 1. Получение значения типа UiNib, соответствующее xib-файлу кастомной ячейки
        let cellTypeNib = UINib(nibName: "TaskTypeCell", bundle: nil)
        
        // 2. Регистрация кастомной ячейки в табличном представлении
        tableView.register(cellTypeNib, forCellReuseIdentifier: "TaskTypeCell")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return taskTypesInformation.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 1. Получение переиспользуемой кастомной ячейки по ее идентификатору
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskTypeCell", for: indexPath) as! TaskTypeCell
        
        // 2. Получение текущего элемента, с информацией которая должна быть выведена
        let typeDescription = taskTypesInformation[indexPath.row]
        
        // 3. Заполнение ячейки данными
        cell.typeTitle.text = typeDescription.title
        cell.typeDescription.text = typeDescription.description
        
        // 4. Отмечаем выбранный тип галочкой
        if selectedType == typeDescription.type {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Получение выбранного типа
        let selectedType = taskTypesInformation[indexPath.row].type
        
        // Вызов обработчика
        doAfterTypeSelected?(selectedType)
        
        navigationController?.popViewController(animated: true)
    }
}
