class TaskList

  def initialize(filename)
    @filename = filename
    @taskList = []
    
    load()
  end

  def each 
    @taskList.each { |t| yield t }
  end
  
  
  ######
  # allocate timeItem to appropriate task Items
  # several scenarios
  # 1. new timeItem and therefore new taskItem
  # 2. timeItem applies to existing timeItem
  # 3. timeItem is being moved from one item to another item by time rename
  # 4. timeItem is being renamed, with the intent to rename all other tasks and time
  # I can't distinguish between 3 and 4, so I choose 3 (more paper like)
  # Option 3 has a few scenarios
  # 1. Old Task only has one time entry - delete?
  # 2. New Task has existing entries - merge?
  # 3. New Task is new and needs to be created
  # 4. Old Task has multiple other time entries - rename? (is this original scenario 4?)
  ######
  def allocate(timeItem, newName)
    oldTask = timeItem.old_task_item
    newTask = lookup(newName)
    
    if newTask.nil? && (oldTask.nil? || oldTask == unnamed_task)
      # in this case we know we are going to be creating a new task
      newTask = add(newName)
    end
    
    
    # if task is new, oldName = nil
    unless oldTask == newTask 
      # do nothing, if the task isn't changing
      
      if (oldTask.nil? || oldTask == unnamed_task)
        
        # allocate time to new task, that's it!
        newTask.addTime(timeItem) 
      
      else
        
        # time already allocated to oldTask
        if newTask.nil?
          if (oldTask.count) == 1 # only this task being renamed so don't ask
            response = Qt::MessageBox::Yes
          else
            response = Debug.yesNoCancel("There are #{oldTask.count-1} other items allocated to '#{oldTask.name}'.  Do you also wish to rename them to '#{newName}'? If not, a new task will be created and notes copied.")
          end
          
          if response == Qt::MessageBox::Yes
            
            # rename old task
            oldTask.name = newName
            newTask = oldTask
          
            # TODO notify time display widgets
            newTask.each do |ti|
              ti.notify_of_task_rename()
            end
          end
          
          if response == Qt::MessageBox::No
            newTask = add(newName)
            newTask.notes = oldTask.notes
            oldTask.removeTime(timeItem)
            newTask.addTime(timeItem)
          end 
          
          if response == Qt::MessageBox::Cancel
            cancel rename
            newTask = oldTask
            timeItem.notify_of_task_rename # renaming back to original name
          end
          
        else
          # TODO confirm potential merger with user
          response = Debug.okCancel("There is already a task named '#{newTask.name}' with #{newTask.count} items logged.  Do you want to merge '#{oldTask.name}' and its #{oldTask.count} items?")
          if response == Qt::MessageBox::Ok
          
            newTask.notes += "\n\n- Notes prior to rename from '#{oldTask.name}' - \n\n #{oldTask.notes}" if !(oldTask.notes.nil? || oldTask.notes.empty?)
          
            # remove all oldTask time and add to newTask
            oldTask.each do |ti|
              newTask.addTime(ti)
              ti.task_item = newTask
              ti.notify_of_task_rename
            end
            
            oldTask.removeAllTime
            oldTask.notes = nil?
          else
            # cancel merge
            newTask = oldTask
            timeItem.notify_of_task_rename # renaming back to original name
          end
        end
      end
    end    
        
    newTask
  end
  
  def deallocate(timeItem)
    timeItem.taskItem.removeTime(timeItem)
  end
  
  def unnamed_task
    @unnamed_task ||= lookup(TimeItem.unnamed)
    @unnamed_task
  end
  
  def lookup(name)
    
    result = nil
    
    unless name.nil? || @taskList.nil?
      @taskList.each do |t|
        result = t if t.name == name
      end
    end
    
    result
  end
  
  def add(taskName)
    task = TaskItem.new(taskName)
      
    @taskList << task
    task
  end
  
  def save()
    begin 
      File.open(@filename, 'w') do |f|
        f.puts Marshal::dump(@taskList)
      end
    rescue
      Debug.alert("Failed to save task data") # will break because QT is finished
    end
  end
  
  def load()
    begin
      data = ""
      File.open(@filename, 'r') do |f|
        while line=f.gets
          data+=line
        end
      end
          
      taskListUnMarshalled = Marshal::load(data)
      
      taskListUnMarshalled.each do | t |
        task = TaskItem.new(nil)
        task.name = t.name
        task.notes = t.notes
        @taskList << task
      end
      
    rescue
      Debug.alert("Failed to task load data")
    end
  end
  
end