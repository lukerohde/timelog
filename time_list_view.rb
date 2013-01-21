
# TimListView responsibilies
#   Render time items - add widget for each time item, set heights to pixel/minute
#   Insert time item - create time entry, insert widget, reset heights to pixel/minute
#   Delete time item - merge time into prev, delete time entry, reset heights to pixel/min
#   Capture insert signal - Time item display widgets emit insert signals
#   Capture delete signal - Time item display widgets emit delete signals
#   Capture Task Done signal - Time item emits done, check for merge, focus on unbilled
#   Grow unbilled - Add elapsed time in 5 min chunks to unbilled item (in last place)
#   Interpret slider events - Translate slider movements into changes in time allocation 
  
class TimeListView < Qt::Widget
  
  signals 'timeList_updated(QVariant)' # used to relay a timeItemView update to parent
  signals 'logging_finished()' # used to signal that the user has logged all unbilled time
  signals 'task_changed(QVariant)' # emitted when a time item with a different task item is focussed or the task of the item in focus is changed
  
  slots 'splitterMoved(int, int)' # handle changes from splitter
  slots 'delete(QVariant)' # handle delete request from timeItemDisplay
  slots 'insertBefore(QVariant)' # handle insertBefore request from timeItemDisplay
  slots 'taskDone(QVariant)' # handle enter key press from timeItemDisplay
  slots 'poll()' # handle progression of time (growing time)
  slots 'timeItemView_updated(QVariant)'
  slots 'gotFocus(QVariant)' # called when a timeItemView gets focus, passes self
  
  attr_accessor :min_times
 
  ######
  # setup time display widget
  ######
  def initialize(timeList, parent = nil)
    super(parent) 
    
    @timeList = timeList
    @min_time_item_height = 45 # this is bad
    
    @layout = Qt::HBoxLayout.new(self)
    
    # Removed because of seg fault caused when attempting to replace splitter
    #@scroll = Qt::ScrollArea.new()
    #@scroll.setWidgetResizable(true)
    #@scroll.setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff)
    #@layout.addWidget(@scroll)
    
    setupTimeList(timeList)
    
    @timer = Qt::Timer.new(self);
    connect(@timer, SIGNAL('timeout()'), self, SLOT('poll()'))
    @timer.start(10000) # every 10 seconds
  end 
  
  #######
  # Logs unbilled time to last billed item
  ####### 
  def sameAgain()
    if @splitter.widget(0).timeItem.task == "#{TimeItem.unnamed}"
      delete(@splitter.widget(0))
    end
  
    emit(logging_finished())
  end
  
  #######
  # Logs unbilled time as "unbilled - away"
  ####### 
  def away()
    if @splitter.widget(0).timeItem.task == "#{TimeItem.unnamed}"
      # log unbilled to "unbilled away"
      @splitter.widget(0).timeItem.task = "#{TimeItem.unnamed} - away"
      merge_if_needed(@splitter.widget(0))
    end
  
    emit(logging_finished())
  end
  
  ######
  # Set focus on last time display item
  ######
  def setFocus()
    @splitter.widget(0).setFocus
  end
  
private
  
  #######
  # Builds/rebuilds the time display widgets.
  # Rebuild is done when we want to delete a widget because of various problems
  ####### 
  def setupTimeList(timeList)
    disconnect(@splitter, SIGNAL('splitterMoved(int, int)'), self, SLOT('splitterMoved(int, int)'))
    
    ##### replacing the spitter the following way caused a segmentation fault, when called from taskDone 
    #@splitter = Qt::Splitter.new(Qt::Vertical)
    #@scroll.setWidget(@splitter)
    ##### the following method solves it by hiding the old scroll and creating a new one
    
    # remove old scroll
    unless @scroll.nil?
      @scroll.hide
      @layout.removeWidget(@scroll) unless @scroll.nil?
      @scroll = nil
    end
    
    # create new scroll
    @scroll = Qt::ScrollArea.new()
    @scroll.setWidgetResizable(true)
    @scroll.setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff)
    
    # set up new splitter
    @splitter = Qt::Splitter.new(Qt::Vertical)
    @scroll.setWidget(@splitter)
    
    # insert new scroll
    @layout.insertWidget(1, @scroll)
    ######## End of segmentation fault work around
    
    # setup display items for each time item
    timeList.each do |ti| 
      insertTimeItemView(ti)
    end 
    
    # Allocate unlogged time
    grow_last_entry()
    
    # Setup timeItem sizes and fix splitter so it can't resize its children
    setHeights(sizes)

    # lock all widgets except the first two
    for j in 2..(@splitter.count-1)
      @splitter.widget(j).lock
    end
    
    styleSplitterHandles
    
    connect(@splitter, SIGNAL('splitterMoved(int, int)'), self, SLOT('splitterMoved(int, int)'))
  end
  
  #######
  # Inserts a timeItem at index position.
  # If no index is supplied, then timeItem will be inserted as index 0
  ####### 
  def insertTimeItemView(timeItem, index = nil)
    
    newItem = TimeItemView.new(timeItem, parent)
    connect(newItem, SIGNAL('insert(QVariant)'), self, SLOT('insertBefore(QVariant)'))
    connect(newItem, SIGNAL('delete(QVariant)'), self, SLOT('delete(QVariant)'))
    connect(newItem, SIGNAL('done(QVariant)'), self, SLOT('taskDone(QVariant)'))
    connect(newItem, SIGNAL('timeItemView_updated(QVariant)'), self, SLOT('timeItemView_updated(QVariant)'))
    connect(newItem, SIGNAL('gotFocus(QVariant)'), self, SLOT('gotFocus(QVariant)'))
    
    if index.nil?
      @splitter.addWidget(newItem)
    else
      @splitter.insertWidget(index, newItem) 
      
      h = @splitter.handle(index)
      unless h.nil?
        box = Qt::VBoxLayout.new(h)
        box.spacing = 0
        box.margin = 0
        
        line = Qt::Frame.new(h)
        line.frameShape = Qt::Frame::HLine
        line.frameShadow = Qt::Frame::Sunken
        box.addWidget(line)
      end
    end
    
    newItem
  end
  
  #######
  # Catches user hitting enter on a widget.  
  # - If same task as previous item, merges them
  # - If unbilled, merges into previous item (shortcut for clicking Same Again)
  # - If the last entry is unbilled time, sets focus upon it
  #######
  def taskDone(widget)
    merge_if_needed(widget) # checks to see if user has entered two items consecutive items the same, and merges them
    
    # if enter is hit on unbilled time, it is merged into the previous task (same as again)
    if widget.timeItem.task == "#{TimeItem.unnamed}"
      delete(widget)
    end
    
    if @splitter.widget(0).timeItem.task == "#{TimeItem.unnamed}"
      @splitter.widget(0).setFocus
    else
      emit(logging_finished())
    end
  end
  
  ######
  # When a time item gets focus, we want to highlight it and check if the task in focus
  # has changed, and if so send notice.
  ######
  def gotFocus(timeItemView)
    focusTask(timeItemView.timeItem)
    
    if timeItemView != @inFocus
      @inFocus.highlight(false) unless @inFocus.nil?
      @inFocus = timeItemView
      @inFocus.highlight(true)
    end
  end
  
  ######
  # When a time item gets updated, we want to check if the task in focus has changed 
  # and if so, send notice.
  ######
  def timeItemView_updated(widget)
    if widget == @inFocus 
      focusTask(widget.timeItem) unless(widget.nil?)
    end
    emit(timeList_updated(widget))
  end
  
  ######
  # Checks if task in focus needs to be changed and sends notice
  ######
  def focusTask(timeItem)
    #Debug.alert("focusing old: #{@taskInFocus} new: #{taskItem}")
    unless timeItem.nil?
      if timeItem.task_item != @taskInFocus
        #Debug.alert("emitting")
      
        emit(task_changed(timeItem)) unless timeItem.nil?
        #parent.task_changed(taskItem) unless taskItem.nil?
        @taskInFocus = timeItem.task_item
      end
    end
  end
  
  ######
  # If the previous widget is the same task, then merge the two
  ######
  def merge_if_needed(widget1)
    i = @splitter.indexOf(widget1)
    widget2 = @splitter.widget(i+1)
    unless widget2.nil?
      if widget1.timeItem.task == widget2.timeItem.task 
        delete(widget1) # pushes time into next task
      end
    end
  end
    
  ######
  # Creates new time display item time item, before the supplied widget
  # Also catches add task signal from user on widget
  ######
  def insertBefore(widget)
  
    # insert widget at index of calling widget
    i = @splitter.indexOf(widget)
    
    # insert widget into data (for saving)
    ti = @timeList.insertTimeItem(i, nil, widget.timeItem.end_time, 0)
    
    # create new display widget for time item
    insertTimeItemView(ti, i)
    
    # reset sizes
    setHeights(sizes)
    
    # lock all widgets
    for j in 0..(@splitter.count-1)
      @splitter.widget(j).lock
    end
    
    # unlock calling widget and new widget so only time can is sharable between these
    widget.unlock
    @splitter.widget(i).unlock # should undo setMaximumHeight too
  end
  
  ######
  # Deletes widget
  ######
  def delete(widget)
    i = @splitter.indexOf(widget)
    
    #next widget
    w = @splitter.widget(i+1)
    
    # Goes to extreme lengths to delete a widget and set to nil
    # This was part of trying to figure out how to get rid of a QT widget
    # I failed to delete it and attempted to hide it.  
    # In the end, I decided to rebuild the splitter
    unless w.nil?
      w.timeItem.time_secs += widget.timeItem.time_secs
      widget.timeItem.time_secs = 0
      widget.disconnectSignals()
      widget.hide()
      widget.setFixedHeight(0)
      widget = nil
      @timeList.delete_at(i)
      emit(timeItemView_updated(nil)) # should be emitted from timeList or timeItem?
      
      # couldn't get widget deleting or hiding to work so...
      #setHeights(sizes)  
      setupTimeList(@timeList) # rebuild splitter instead
    end  
  end
  
  
  ######
  # Gets an array of desired time display widget heights
  # Used for setting splitter sizes.  
  ######
  def sizes
    s = []
    #Debug.alert(@timeList.count)
    for i in 0..(@splitter.count-1)
      w = @splitter.widget(i)
      # Unsure if setSizes wants to set hidden controls (indicated by timeItem.nil?), 
      unless w.timeItem.nil?
        s << (w.timeItem.time_secs/60).to_i + @min_time_item_height
      else
        s << 0 # Specify zero for hidden time item
      end
    end
    s
  end
  
  ######
  # Get count of hidden items
  ######
  def hiddenCount
    cnt = 0 
    for i in 0..(@splitter.count-1)
      w = @splitter.widget(i)
      cnt += 1 if w.timeItem.nil?
    end
    
    cnt
  end
  
  ######
  # Catch splitterMoved event
  ######
  def splitterMoved(pos, index)
    # Change time allocation based upon relative sizes of time display widgets
    setTimesFromHeights()
  end
  
  ######
  # Set heights for widgets and splitter based upon times for each time item
  # 1 minute = 1 pixel + minimum widget size and spacing.
  ######
  def setHeights(sizes)
    s = sizes
    
    # determine splitter height by adding size of widgets and spacing 
    splitter_height = 0
    s.each { |i| splitter_height += i + 7 } #  magic number is space between controls
    splitter_height -= 7 * hiddenCount() # subtract spacing for hidden controls. 
    
    # fix splitter height so it can't be resized (which would affect widget heights)
    @splitter.setSizePolicy(Qt::SizePolicy::Expanding, Qt::SizePolicy::Fixed)
    @splitter.setMinimumHeight(splitter_height) 
    @splitter.setMaximumHeight(splitter_height)  
    
    # Set widget sizes
    @splitter.setChildrenCollapsible(false)
    @splitter.setSizes(sizes) #assuming sizes need to be supplied for hidden items too?! 
    
    #Debug.alert("sizes #{sizes.to_s} total_height #{total_height}")
  end
  
  ######
  # User can adjust time splits, to change time allocation between tasks
  # So widget heights can determine time allocation
  # 1 pixel = 1 minute - minimum widget size
  # time can only be distributed between widgets, so time after redistribution
  # should equal time before redistribution
  ######
  def setTimesFromHeights()
    @doNotGrow = true # prevents timer event resizing things during redistribution
    
    # get total time before redistributing it (should be same after)
    start_total = total_time_mins
    
    # get the earliest logged time ( for working out start and end times for widgets)
    time_i = min_time
    cnt = 0 # for debugging
    
    # iterate from oldest time entry (index = n-1) to newest time (index = 0)
    lastIndex = @splitter.count-1
    lastIndex.downto(0) do |i|
      w = @splitter.widget(i)
      
      unless w.timeItem.nil? # nil time item indicates hidden/deleted
        cnt += 1 # count visible (non hidden items)
        if w.maximumHeight == w.minimumHeight # when time item display is locked
          # Determine time from what the height should be, less widget size
          h = w.maximumHeight - @min_time_item_height
        else
          # Determine time from what the height is, less widget size
          h = w.height - @min_time_item_height
        end
        
        # round time to multiple of 5 (makes setting time in neat increments easier, with less mouse precision)
        w.timeItem.time_secs = (h - (h % 5)) * 60
        
        # set start of task to end of the previous
        w.timeItem.start_time = time_i 
        time_i += (w.timeItem.time_secs)
      end
      
      @doNotGrow = false # prevents timer event resizing things during redistribution
    end
    
    # warn user if redistribution has affected total time by more than 5 mins (rounding)
    if (start_total-total_time_mins).abs > 5
      Debug.alert("Warning, splitter varied timings! User set:  #{start_total}  splitter set: #{total_time_mins}  DIFF: #{start_total-total_time_mins} WIDGETS: #{@splitter.count} VISIBLE: #{cnt}") 
    end
  end
  
  ######
  # Get total time allocated
  ######  
  def total_time_mins
    time_i = 0

    @timeList.each do |ti|
      time_i += ti.time_secs
    end
    
    time_i / 60
  end
  
  ######
  # Make splitter handles more prominent
  ######
  def styleSplitterHandles
  
    # paint splitter handles
    for i in 1..(@splitter.count - 1) # index 0 has no handle
      h = @splitter.handle(i)
      # Debug.alert(h.count().to_s) # TODO don't add if already added?
      box = Qt::VBoxLayout.new(h)
      box.spacing = 0
      box.margin = 0
      
      line = Qt::Frame.new(h)
      line.frameShape = Qt::Frame::HLine
      line.frameShadow = Qt::Frame::Sunken
      box.addWidget(line)
    end
  end
  

  ######
  # As time ticks by, grow splitter and last widget
  # Only add grow if time has ticked past the next 5 minute interval
  # Only add time to unbilled (so it is clear to the user what they've logged
  # and haven't.  This means adding a widget if the last entry isn't "unbilled"
  ######  
  def grow_last_entry()
    return if @doNotGrow
    
    time_diff_mins = ((Time.now - min_time)/60).to_i - total_time_mins
    
    # Only grow if the enough minutes has passed to reach the next 5 min interval
    next_total_time = total_time_mins + time_diff_mins
    next_total_time -= next_total_time % 5 # round down to last 5 min interval
    time_diff_mins = next_total_time - total_time_mins # only enough minutes to get to the next interval
    
    # if the next interval (once rounded down) is after the last interval then...
    if next_total_time > total_time_mins then 
      last_entry = @splitter.widget(0)
      if last_entry.timeItem.task != "#{TimeItem.unnamed}"
        # will only grow a timeItem called unbilled (insert it if last item isn't)
        insertBefore(last_entry)
        last_entry = @splitter.widget(0)
      end
      last_entry.timeItem.time_secs += (time_diff_mins * 60)
    end
  end
  
  ######
  # Get the earliest time logged
  ######
  def min_time
    @splitter.widget(@splitter.count-1).timeItem.start_time
  end
  
  ######
  # Background polling for growing last time entry
  ######
  def poll()
    grow_last_entry()
    setHeights(sizes)
  end
end