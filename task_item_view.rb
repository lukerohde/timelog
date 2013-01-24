class TaskNotesEdit < Qt::TextEdit
  signals "taskNotes_focusOut()"

  def focusOutEvent(event)
    emit(taskNotes_focusOut())
  end
end


class TaskItemView < Qt::Widget

  slots 'text_textChanged()'

  def initialize()
    super()
    @layout = Qt::VBoxLayout.new()
    
    @task = nil
    @text = TaskNotesEdit.new()
    @text.readOnly = true
    @layout.addWidget(@text)
    
    setLayout @layout
    
    connect(@text, SIGNAL('taskNotes_focusOut()'), self, SLOT('text_textChanged()'))
  end
  
  def task=(taskItem)
    @task = taskItem
    @text.readOnly = false
    @text.plainText = @task.notes unless @task.nil?
  end
  
  def text_textChanged()
    @task.notes = @text.plainText
  end
end