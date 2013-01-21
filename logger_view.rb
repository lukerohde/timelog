
# LoggerView window responsibilities
#   Main window layout, including time list display
#   Again button - pop unbilled time (adding time to prev), reset popup countdown, minimise
#   Away button - rename unbilled time 'unbilled - away', reset popup countdown, minimise
#   Done button - dismiss timer (minimises)
#   Popup interval slider - reset popup countdown
#   Popup timer - restore window when popup countdown elapses
#   Load and save time list

class LoggerView < Qt::MainWindow
  
  slots 'away_clicked()'
  slots 'sameAgain_clicked()'
  slots 'done_clicked()'
  slots 'timeItemView_updated(QVariant)' #
  slots 'logging_finished()'
  slots 'resetPopupCountDown()' # handle popup interval change by resetting countdown
  slots 'poll()'
  slots 'scheduledSave()'
  slots 'task_changed(QVariant)'
  
  attr_accessor :min_time
 
  ######
  # Setup main LoggerView window
  ######
  def initialize(timeList, taskList)
    super() 
    
    @timeList = timeList
    @taskList = taskList
    
    timeLayout = Qt::VBoxLayout.new()
    
    # setup main time item list display
    @timeListView = TimeListView.new(timeList, self)
    timeLayout.addWidget(@timeListView)
    
    # add buttons
    # setup header button group
    buttonGroup = Qt::HBoxLayout.new()
    
    @sameAgain = Qt::PushButton.new("same again")
    connect(@sameAgain, SIGNAL('clicked()'), self, SLOT('sameAgain_clicked()'))
    buttonGroup.addWidget(@sameAgain)
    
    @away = Qt::PushButton.new("away")
    connect(@away, SIGNAL('clicked()'), self, SLOT('away_clicked()'))
    buttonGroup.addWidget(@away)
    
    @done = Qt::PushButton.new("done")
    connect(@done, SIGNAL('clicked()'), self, SLOT('done_clicked()'))
    buttonGroup.addWidget(@done)
    
    timeLayout.addLayout(buttonGroup)
    
    # setup popup interval selector
    setupPopupIntervalGroup(timeLayout)
    
    taskSplitter = Qt::Splitter.new(Qt::Horizontal)
    
    # setup task view
    @taskItemView = TaskItemView.new()
    
    # setup splitter between, timeList and taskView 
    
    leftSide = Qt::Widget.new();
    leftSide.setLayout( timeLayout );
    taskSplitter.addWidget(leftSide)
    taskSplitter.addWidget(@taskItemView)
    sizes = [100,0]
    taskSplitter.setSizes(sizes)
    
    setCentralWidget(taskSplitter)
    
    connect(@timeListView, SIGNAL('timeList_updated(QVariant)'), self, SLOT('timeItemView_updated(QVariant)'))
    connect(@timeListView, SIGNAL('logging_finished()'), self, SLOT('logging_finished()'))
    connect(@timeListView, SIGNAL('task_changed(QVariant)'), self, SLOT('task_changed(QVariant)'))
    
    @taskItemView.setFocus() # TODO why doesn't this work
  end 
  
  def setTask(taskItem)
    @taskItemView.task = taskItem unless taskItem.nil?
  end
  
  ######
  # capture notice when the task in focus changes
  ######
  def task_changed(timeItem)
    self.setTask(timeItem.task_item)
  end
  
private

  ############################
  # SLOTS
  ############################

  ######
  # Capture sameAgain button click
  # User intends to log unbilled time to the same thing they last billed time to
  ######
  def sameAgain_clicked()
    @timeListView.sameAgain()
  end
  
  ######
  # Capture away button click
  # User intends on logging unbilled time to "unbilled away"
  ######
  def away_clicked()
    @timeListView.away()
  end
  
  ######
  # Capture done button click
  # User intends on dismissing the LoggerView
  ######
  def done_clicked()
    resetPopupCountDown()
    self.windowState = Qt::WindowMinimized
  end  
  
  ######
  # Capture event where user has logged all unbilled time
  # Dismiss LoggerView
  ######
  def logging_finished()
    self.windowState = Qt::WindowMinimized
  end
  
  ######
  # Capture timeItem update event (save)
  ######
  def timeItemView_updated(timeItemView)
    resetPopupCountDown() unless !timeItemView.nil? && timeItemView.timeItem.task == TimeItem.unnamed
    
    if !@save_scheduled == true
      @save_scheduled = true
      Qt::Timer::singleShot(5000, self, SLOT('scheduledSave()'));
    end
  end
  
 
  
  ######
  # Save periodically, triggered shortly after at least one update.  The splitter can 
  # cause several update events to fire so we don't want to save after ever update.
  ######
  def scheduledSave()
    @timeList.save
    @taskList.save
    @save_scheduled = false
  end
  
  ############################
  # END OF SLOTS
  ############################


  ######
  # Setup popUp interval slider (at bottom of screen)
  ######
  def setupPopupIntervalGroup(layout)
    popupIntervalGroup = Qt::HBoxLayout.new()
    @popupIntervalSlider = Qt::Slider.new(Qt::Horizontal)
    @popupIntervalSlider.setRange(0, 60)
    @popupIntervalLCD = Qt::LCDNumber.new(2)
    popupIntervalGroup.addWidget(@popupIntervalSlider)
    popupIntervalGroup.addWidget(@popupIntervalLCD)
    layout.addLayout(popupIntervalGroup)
    
    # setup popup timer interval (needs to be set before
    @timer = Qt::Timer.new(self);
    connect(@timer, SIGNAL('timeout()'), self, SLOT('poll()'))
    @timer.start(60000)
    
    connect(@popupIntervalSlider, SIGNAL("valueChanged(int)"), @popupIntervalLCD, SLOT("display(int)"))
    connect(@popupIntervalSlider, SIGNAL("valueChanged(int)"), self, SLOT("resetPopupCountDown()"))
    
    @popupIntervalSlider.value=15 #TODO persist user preference
  end
  
  ######
  # Check in on a regular interval to see if anything should be done
  ######
  def poll()
    if Time.now > @nextPopupTime
      self.show()
      self.raise()
      self.activateWindow()
      #@timeListView.setFocus # annoying when application already has focus and notes are being typed
      resetPopupCountDown()
    end
  end

  ######
  # Start popup count again, based on slider
  ######
  def resetPopupCountDown()
    @timer.stop()
    @timer.start(60000)
    @nextPopupTime = Time.now + (@popupIntervalSlider.value * 60)
  end
  
 end