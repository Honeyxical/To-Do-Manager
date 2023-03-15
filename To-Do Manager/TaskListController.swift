import UIKit

class TaskListController: UITableViewController {

    var taskStorage: TaskStorageProtocol = TaskStorage()
    var tasks: [TaskPriority: [TaskProtocol]] = [:] {
        didSet{
            for (taskGroupPriority, taskGroup) in tasks {
                tasks[taskGroupPriority] = taskGroup.sorted{ task1, task2 in
                    let task1position = taskStatusPosition.firstIndex(of: task1.status) ?? 0
                    let task2position = taskStatusPosition.firstIndex(of: task2.status) ?? 0
                    return task1position < task2position
                }
            }
            var savingArray: [TaskProtocol] = []
            tasks.forEach{ _, value in
                savingArray += value
            }
            taskStorage.saveTasks(tasks: savingArray)
        }
    }
    var taskStatusPosition: [TaskStatus] = [.planned, .completed]
    
    var sectionsTypePosition: [TaskPriority] = [.important, .normal]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if tasks[sectionsTypePosition[1]]?.count != 0 || tasks[sectionsTypePosition[0]]?.count != 0{
            navigationItem.leftBarButtonItem = editButtonItem
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if tasks[sectionsTypePosition[1]]?.count != 0 || tasks[sectionsTypePosition[0]]?.count != 0{
            navigationItem.leftBarButtonItem = editButtonItem
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toCreateScreen" {
            let destination = segue.destination as! TaskEditController
            destination.doAfterEdit = { [unowned self] title, type, status in
                let newTask  = Task(title: title, type: type, status: status)
                tasks[type]?.append(newTask)
                tableView.reloadData()
            }
        }
    }
    
    // MARK: - Заголовок секции
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String?
        let tasksType = sectionsTypePosition[section]
        if tasksType == .important{
            title = "Important"
        } else {
            title = "Normal"
        }
        return title
    }

    // MARK: - Количество секций в таблице
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tasks.count
    }
    
    // MARK: - Количество строк в определенной секции
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let taskType = sectionsTypePosition[section]
        
        if taskIsExist(taskType: taskType){
            return 1
        }
        
        return tasks[taskType]!.count
    }
    
    //MARK: - Присвоение задаче статус выполнена по нажатию на нее
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 1. Проверка на существование задачи
        let taskType = sectionsTypePosition[indexPath.section]
        
        if taskIsExist(taskType: taskType){
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        guard let _ = tasks[taskType]?[indexPath.row] else {
            return
        }
        
        // 2. Проверка на статус задачи. В данном случае она не должна быть выполнена
        guard tasks[taskType]![indexPath.row].status == .planned else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        // 3. Присваивание задаче статус выполнено
        tasks[taskType]![indexPath.row].status = .completed
        
        // 4. Обновление секции таблицы
        tableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .automatic)
    }
    
    //MARK: - Присвоение задаче статус запланирована, при свайпе по задаче
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // 1. Получение данных о задаче которую необходимо отметить как запланированную
        let taskType = sectionsTypePosition[indexPath.section]
        
        if taskIsExist(taskType: taskType){
            return nil
        }
        
        guard let _ = tasks[taskType]?[indexPath.row] else {
            return nil
        }
                
        // 2. Создание действия для изменения статуса
        let actionSwipeInstance = UIContextualAction(style: .normal, title: "Not completed") {
            _, _, _ in
            self.tasks[taskType]![indexPath.row].status = .planned
            self.tableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .automatic)
        }
        // 3. Создание действия для перехода к экрану редактирования
        let actionEditInstance = UIContextualAction(style: .normal, title: "Edit"){ _, _, _ in
            // Загрузка сцены из сториборда
            let editScreen = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TaskEditController") as! TaskEditController
            
            // Передача значений редактируемой задачи
            editScreen.taskType = self.tasks[taskType]![indexPath.row].type
            editScreen.taskText = self.tasks[taskType]![indexPath.row].title
            editScreen.taskStatus = self.tasks[taskType]![indexPath.row].status
            
            // Передача обработчика для сохранения задачи
            editScreen.doAfterEdit = { [unowned self] title, type, status in
                let editedTask = Task(title: title, type: type, status: status)
                tasks[taskType]![indexPath.row] = editedTask
                tableView.reloadData()
            }
            self.navigationController?.pushViewController(editScreen, animated: true)
        }
        
        // Изменение цвета фона кнопки действием
        actionEditInstance.backgroundColor = .darkGray
        
        // Создание объекта, описывающего доступные действия в зависимости от статуса задачи. Будет отображено одно или два действия
        let actionsConfiguration: UISwipeActionsConfiguration
        if tasks[taskType]![indexPath.row].status == .completed{
            actionsConfiguration = UISwipeActionsConfiguration(actions: [actionSwipeInstance, actionEditInstance])
        } else {
            actionsConfiguration = UISwipeActionsConfiguration(actions: [actionEditInstance])
        }
        
        return actionsConfiguration
    }
    
    // MARK: - Удаление строчки через режим редактирования
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let taskType = sectionsTypePosition[indexPath.section]
        
        if taskIsExist(taskType: taskType){
            return
        }
        
        tasks[taskType]?.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .right)
        
    }
    
    // MARK: - Перемещение строк в режиме редактирования
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    
        // Получение секции из которой необходимо переместить строку
        let taskTypeFrom = sectionsTypePosition[sourceIndexPath.section]
        
        // Получение секции в которую происходит перемещение
        let taskTypeTo = sectionsTypePosition[destinationIndexPath.section]
        
        // Безоспасное извлечение задачи и копирование задачи
        guard let movedTask = tasks[taskTypeFrom]?[sourceIndexPath.row] else {
            return
        }
        
        // Удаление задачи с места, откуда она перенесена
        tasks[taskTypeFrom]!.remove(at: sourceIndexPath.row)
        
        // Вставка задачи на новую позицию
        tasks[taskTypeTo]!.insert(movedTask, at: destinationIndexPath.row)
        
        // Если секция изменилась, изменяем тип задачи в соответствии с новой позицией
        if taskTypeFrom != taskTypeTo {
            tasks[taskTypeTo]![destinationIndexPath.row].type = taskTypeTo
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Ячейка для строки таблицы
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return getConfigurationTaskCell_stack(indexPath: indexPath)
    }
    
    func setTasks (_ taskCollection: [TaskProtocol]){
        // Подготовка коллекции с задачами
        // Берутся только те задачи, у которых определена секция
        sectionsTypePosition.forEach{ taskType in
            tasks[taskType] = []
        }
        
        // загрузка и разбор задач из хранилища
        taskCollection.forEach{task in
            tasks[task.type]?.append(task)
        }
    }
    
    // MARK: - Ячейка на основе ограничений
    private func getConfiguratedTaskCell_constraints(for indexPath: IndexPath) -> UITableViewCell{
        
        //Загружаем прототип ячейки по идентификатору
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskCellConstraints", for: indexPath)
        
        // Получаем данные о задаче, которую необходимо вывести в ячейке
        let taskType = sectionsTypePosition[indexPath.section]
        guard let currentTask = tasks[taskType]?[indexPath.row] else {
            return cell
        }
        
        // Текстовая метка символа
        let symbolLabel = cell.viewWithTag(1) as? UILabel
        // Текстовая метка названия задачи
        let textLabel = cell.viewWithTag(2) as? UILabel
        
        // Изменяем символ в ячейке
        symbolLabel?.text = getSymbolForTask(with: currentTask.status)
        // Изменяем текст в ячейке
        textLabel?.text = currentTask.title
        
        // Изменяем цвет текста и символа
        if currentTask.status == .planned{
            textLabel?.textColor = .black
            symbolLabel?.textColor = .black
        } else {
            textLabel?.textColor = .lightGray
            symbolLabel?.textColor = .lightGray
        }
        
        return cell
    }

    // MARK: - Ячейка на основе стека
    private func getConfigurationTaskCell_stack(indexPath: IndexPath) -> UITableViewCell{
        // Получение ячейки по идентификатору
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskCellStack", for: indexPath) as! TaskCell
        // Получение данных о задаче, которую необходимо вывести в ячейке
        let taskType = sectionsTypePosition[indexPath.section]
        
        if taskIsExist(taskType: taskType) {
            cell.title.text = "Have no tasks"
            cell.title.textColor = .lightGray
            cell.symbol.text = ""
            cell.symbol.textColor = .lightGray
            return cell
        }
        
        let currentTask = tasks[taskType]?[indexPath.row]
        
        cell.title.text = currentTask?.title
        
//        guard let currentTask = tasks[taskType] else {
//            cell.title.text = "Have no tasks"
//            cell.title.textColor = .lightGray
//            return cell
//        }
//
//        // Изменение названия ячейки
//        cell.title.text = currentTask.title
//        // Изменение символа в ячейке
        cell.symbol.text = getSymbolForTask(with: tasks[taskType]?[indexPath.row].status as! TaskStatus)
//
        // Изменение цвета
        if currentTask?.status == .planned {
            cell.title.textColor = .black
            cell.symbol.textColor = .black
        } else {
            cell.title.textColor = .lightGray
            cell.symbol.textColor = .lightGray
        }
        return cell
    }
    
    // Возвращаем символ для соответствующего типа задачи
    private func getSymbolForTask(with status: TaskStatus) -> String {
        var resultSymbol: String
        if status == .planned{
            resultSymbol = "\u{25CB}"
        } else if status == .completed {
            resultSymbol = "\u{25C9}"
        } else {
            resultSymbol = ""
        }
        return resultSymbol
    }
    
    private func taskIsExist(taskType: TaskPriority) -> Bool{
        return tasks[taskType]?.count == 0
    }
    
}
