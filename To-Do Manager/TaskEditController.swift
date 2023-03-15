import UIKit

class TaskEditController: UITableViewController {
    var taskText: String = ""
    var taskType: TaskPriority = .normal
    var taskStatus: TaskStatus = .planned
    
    var doAfterEdit: ((String, TaskPriority, TaskStatus) -> Void)?

    private var taskTitles: [TaskPriority: String] = [
        .important: "Important",
        .normal: "Normal"
    ]
    
    @IBOutlet weak var taskTitle: UITextField!
    @IBOutlet weak var taskTypeLabel: UILabel!
    @IBOutlet weak var taskStatusSwitch: UISwitch!
    
    @IBAction func saveTask(_ sender: UIBarButtonItem) {
        let title = taskTitle.text?.trimmingCharacters(in: .whitespaces)
        let type = taskType
        let status: TaskStatus = taskStatusSwitch.isOn ? .completed : .planned
        
        if title != "" {
            doAfterEdit?(title!, type, status)
            navigationController?.popViewController(animated: true)
        }
        let allertWarning = UIAlertController(title: "Field title is empty", message: "Add title to your task", preferredStyle: .alert)
        allertWarning.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(allertWarning, animated: true)
        taskTitle.text = ""
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        taskTitle?.text = taskText
        taskTypeLabel?.text = taskTitles[taskType]
        taskStatusState(switcher: taskStatusSwitch, taskStatus: taskStatus)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 3
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Ссылка на контроллер назначения
        if segue.identifier == "toTaskTypeScreen"{
            // Передача выбранного типа
            let destination = segue.destination as! TaskTypeController
            // Передача выбранного типа
            destination.selectedType = taskType
            // Передача обработчика выбора типа
            destination.doAfterTypeSelected = { [unowned self] selectedType in
                taskType = selectedType
                taskTypeLabel.text = taskTitles[taskType]
            }
        }
    }
    
    private func taskStatusState(switcher: UISwitch, taskStatus: TaskStatus){
        if taskStatus == .completed{
            switcher.isOn = true
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
