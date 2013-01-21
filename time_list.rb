class TimeList < Qt::Object # only needed for weird connection between timeItem and timeList
  include Enumerable
  
  attr_reader :taskList
  slots 'timeItem_updated(QVariant)'
  
  def initialize(filename, taskList)
    super()
    
    @filename = filename
    @taskList = taskList
    @timeList = [] 
    
    load()
  end
  
  def each
    @timeList.each { |ti| yield ti }
  end
  
  # Here's the problem 
  # I want user creation of timeItems to drive the creation of tasks
  # But one task item can have one or many time items
  # Each time entry could need to select from all task items
  # Every time item must have one task
  # It seems inappropriate to initialise a time item with the task manager
  # The other way is defer link between time and task to time manager
  # The time manager hooks itself to the task, when updated it updates task manager
  # I'll try that for fun, although it seem retarded when each timeItem needs a taskItem
  # Since each timeItem needs a taskItem, each taskItem could have a parent.
  
  def insertTimeItem(index, name, start_time, time_secs)
    # create new time item widget
    ti = TimeItem.new(@taskList)
    
    connect(ti, SIGNAL('timeItem_updated(QVariant)'), self, SLOT('timeItem_updated(QVariant)'))
    ti.start_time = start_time
    ti.task = name
    ti.time_secs = time_secs
    
    @timeList.insert(index, ti)
    
    ti
  end
  
  def timeItem_updated(timeItem)
    # TODO update task item if has focus and old_task_item <> new_task_item
    
  end
  
  def delete_at(index)
    @timeList.delete_at(index)
  end
    
  def save()
    begin 
      File.open(@filename, 'w') do |f|
        f.puts Marshal::dump(@timeList)
      end
    rescue
      Debug.alert("Failed to save time data") # will break because QT is finished
    end
  end
  
  def load()
    #begin
      data = ""
      File.open(@filename, 'r') do |f|
        while line=f.gets
          data+=line
        end
      end
          
      timeListUnMarshalled = Marshal::load(data)
      
      timeListUnMarshalled.each do | i |
        unless i.nil?
          insertTimeItem(@timeList.count, i.task, i.start_time, i.time_secs)
        end
      end
      
    #rescue
    #  Debug.alert("Failed to load time data")
    #  insertTimeItem(0, nil, Time.now, 0) # data failed to load so add one item starting now
    #end
  end
  
  def loadFake()
    # mock some data
    total_secs = 0
    for i in 0..9
      
      time_secs = SecureRandom.random_number(3600) 
      time_secs = ((time_secs - (time_secs % 300)))
      
      insertTimeItem(@timeList.count, "task #{i}", Time.now, time_secs)
      
      total_secs += ti.time_secs
    end
    
    last_end = Time.now() - 3600 # extra hour
    @timeList.each do |ti|
      ti.start_time = last_end - ti.time_secs
      last_end = ti.start_time
    end
  end
  


end