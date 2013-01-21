
class TimeItem < Qt::Object
  attr_accessor :oldTask
  attr_accessor :task
  attr_accessor :task_item
  attr_accessor :old_task_item
  attr_accessor :time_secs
  attr_accessor :start_time
  attr_reader :end_time
  
  signals 'timeItem_updated(QVariant)'
  
  def initialize(taskList)
    super()
    @taskList = taskList 
    
    @task = TimeItem.unnamed
    @old_task_time = nil
    @task_time = nil
    @old_time_secs = nil
    @time_secs = 0
    @old_start_time = nil
    @start_time = Time.now
  end
  
  def self.unnamed
    "unbilled".to_s
  end
    
  def time_secs=(value)
    @old_time_secs = @time_secs
    @time_secs = value
    emit(timeItem_updated(self)) if @old_time_secs != @time_secs
  end
  
    
  def start_time=(value)
    @old_start_time = @start_time
    @start_time = value 
    emit(timeItem_updated(self)) if @old_start_time != @start_time
  end
  
  def end_time
    start_time + time_secs
  end
  
  def task
    result = TimeItem.unnamed
    result = @task_item.name unless @task_item.nil?
    result
  end
  
  def task=(newTaskName)
    newTaskName = TimeItem.unnamed if newTaskName.nil?
    
    @old_task_name = nil
    @old_task_name = @task_item.name unless @task_item.nil?
    
    # if the name is changing, reallocate time
    if @old_task_name.to_s != newTaskName.to_s
      
      @old_task_item = @task_item
      self.task_item = @taskList.allocate(self, newTaskName)
    
      emit(timeItem_updated(self)) if !@old_task.equal?(@task)
    end
  end
  
  def task_item=(taskItem)
    @task_item = taskItem unless taskItem.nil?
    @task_item = @taskList.lookup(TimeItem.unnamed) if taskItem.nil?
    @task = @task_item.name # only used for marshalling, in lieu of task_id, because users identify tasks by name
    
    #Debug.alert("Allocating:  #{@task_item.name}") unless @task_item.nil?
  end

  def notify_of_task_rename
    emit(timeItem_updated(self)) 
  end

  
  
  def marshal_dump
    [@task, @time_secs, @start_time]
  end
  
  def marshal_load array
    @task, @time_secs, @start_time = array
  end
  
  def to_s
    "#{@start_time} + #{@time_secs/60} mins"
  end
  
  def inspect
    "#{@task} #{@task_item}: #{@start_time} + #{@time_secs/60} mins"
  end
end