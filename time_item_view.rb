class TaskEdit < Qt::LineEdit
  signals "taskEdit_focus(QVariant)"

  def focusInEvent(event)
    emit(taskEdit_focus(self))
  end
end

class TimeItemView < Qt::Frame
  signals 'valueChanged(int)'
  signals 'insert(QVariant)'
  signals 'delete(QVariant)'
  signals 'done(QVariant)' # on line edit
  signals 'timeItemView_updated(QVariant)' # Why can't this be just updated() - chaining TimeItem.updated to TimeItemView.updated causes 'stack level too deep'
  signals 'gotFocus(QVariant)' # timeListView needs to know which time item has focus
  
  slots 'taskEdit_focus(QVariant)'
  slots 'taskEdit_focusOut(QVariant)'
  slots 'timeItem_updated(QVariant)' # send from data
  slots 'insert_clicked()'
  slots 'delete_clicked()'
  slots 'lock_clicked()'
  slots 'timedesc_editingFinished()'
  slots 'returnPressed()'
  slots 'setFocus()'
  
  attr_reader :timeItem
  
  def initialize(ti, parent = nil)
    super(parent)
    self.timeItem = ti
    
    @lock = Qt::PushButton.new("=")
    @lock.setFixedSize(20, 20)
    
    @task = TaskEdit.new()
    @task.setFixedHeight(20)
    connect(@task, SIGNAL('taskEdit_focus(QVariant)'), self, SLOT('taskEdit_focus(QVariant)'))
    
    @delete = Qt::PushButton.new("x")
    @delete.setFixedSize(20, 20)
    
    @insert = Qt::PushButton.new("+")
    @insert.setFixedSize(20, 20)
    
    @timedesc  = Qt::Label.new()
    
    buttons = Qt::HBoxLayout.new()
    buttons.addWidget(@task)
    buttons.addWidget(@lock)
    buttons.addWidget(@delete)
    buttons.addWidget(@insert)
    buttons.setSpacing(10)
    buttons.setMargin(0);
    
    times = Qt::HBoxLayout.new()
    times.addWidget(@timedesc)
    times.setSpacing(10)
    times.setMargin(0);
    @timedesc.setFixedHeight(20)
    
    @spacer = Qt::Widget.new()
    
    @layout = Qt::VBoxLayout.new()
    @layout.addLayout(buttons)
    @layout.addLayout(times)
    @layout.addWidget(@spacer)
    #colour.setStyleSheet("border-color:blue;");
    #self.setStyleSheet("background-color:white;");
    self.setStyleSheet("default;");
    @task.setStyleSheet("background-color:transparent; border: transparent;");
      
    @layout.setMargin(0)
    @layout.setSpacing(0)
    
    setLayout(@layout)
    @minHeight = self.height # minimum height at this point
    setMinimumHeight(45) 
    
    connect(@insert, SIGNAL('clicked()'), self, SLOT('insert_clicked()'))
    connect(@delete, SIGNAL('clicked()'), self, SLOT('delete_clicked()'))
    connect(@lock, SIGNAL('clicked()'), self, SLOT('lock_clicked()'))
    connect(@task, SIGNAL('editingFinished()'), self, SLOT('timedesc_editingFinished()'))
    connect(@task, SIGNAL('returnPressed()'), self, SLOT('returnPressed()'))
    refresh()
  end
  
  def mousePressEvent(event)
    self.setFocus()
  end
  
  def taskEdit_focus(taskEdit)
    emit(gotFocus(self))
    
    # there has got to be a better way
    # the other way is to do it with slots - but this also feels dumb
    #parent.parent.parent.parent.parent.setTask(@timeItem.task_item)
    
    #highlight(true)
  end

  def taskEdit_focusOut(taskEdit)
    #highlight(false)
  end
  
  def highlight(on)
    if on
      #self.each do |child |
        self.setStyleSheet("background-color:grey;");
        @task.setStyleSheet("background-color:white; ");
        #end
    else
      #self.each do |child |
        if @timeItem.start_time.strftime('%Y/%m/%d') !=  @timeItem.end_time.strftime('%Y/%m/%d')
          #TODO refactor with refresh
          self.setStyleSheet("background-color:black; color: white");
        else
          self.setStyleSheet("default;");
          @task.setStyleSheet("background-color:transparent; border: transparent;");
      end
      #end
    end
  end
  
  def disconnectSignals()
    disconnect(@insert, SIGNAL('clicked()'), self, SLOT('insert_clicked()'))
    disconnect(@delete, SIGNAL('clicked()'), self, SLOT('delete_clicked()'))
    disconnect(@lock, SIGNAL('clicked()'), self, SLOT('lock_clicked()'))
    disconnect(@task, SIGNAL('editingFinished()'), self, SLOT('timedesc_editingFinished()'))
    disconnect(@task, SIGNAL('returnPressed()'), self, SLOT('returnPressed()'))
  end
  
  def setFocus()
    @task.setFocus()
  end

  def timeItem=(timeItem)
    @timeItem = timeItem
    connect(@timeItem, SIGNAL('timeItem_updated(QVariant)'), self, SLOT('timeItem_updated(QVariant)'))
  end
  
  def timeItem
    @timeItem
  end
  
  def lock
    self.setFixedHeight(self.height);
    @lock.setText('-')
  end
  
  def unlock
    self.setMinimumHeight(45);
    self.setMaximumHeight(65535);
    @lock.setText('=')
  end
  
  private
  
  def timeItem_updated(timeItem)
    refresh()
    emit(timeItemView_updated(self))
  end

  def refresh
    #Debug.alert("refresh")
    @task.text = @timeItem.task
    
    desc = "#{@timeItem.time_secs / 60} mins:"
    #desc += " - #{@timeItem.task_item}"
    desc += "   #{@timeItem.start_time.strftime('%a %d %b %y, %H:%M')}"
    desc += " - #{@timeItem.end_time.strftime('%H:%M')}"
    @timedesc.setText(desc)
    
    if @timeItem.start_time.strftime('%Y/%m/%d') !=  @timeItem.end_time.strftime('%Y/%m/%d')
      # Indicate night - TODO consider putting daily report here, dumb idea, who wants to wait to the next day for a day summary
      self.setStyleSheet("background-color:black; color: white");
    end
  end
  
  ####################
  # SLOTS
  ####################
  
  def insert_clicked()
    emit insert(self)
  end
  
  def delete_clicked()
    emit delete(self)
  end
  
  def lock_clicked()
    if @lock.text() == '='
      lock
    else
      unlock
    end
  end
    
  def timedesc_editingFinished()
    @timeItem.task = @task.text unless @timeItem.nil?
  end
  
  def returnPressed()
    timedesc_editingFinished()
    emit(done(self))
  end
  
end