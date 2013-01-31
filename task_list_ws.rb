class TaskListWS < TaskList

  def initialize
    @taskItemClass = TaskItemWS
  end

  def each 
    data = WS.get_data("/tasks")
    
    unless data.nil?
      data.each do |t| 
        task = @taskItemClass.new(t["name"], t["notes"])
        yield task
     end
    end
  end
  
  def lookup(name)
    data = WS.get_data("/task/#{WS.encode(name)}")
    
    result = nil
    result = @taskItemClass.new(data["name"], data["notes"]) unless data.nil? 
    result
  end
  
  def add(name)
    response = WS.put_data("/task/#{WS.encode(name)}", {}.to_json)
    lookup(name) # seems a little wasteful
  end
  
  def save()

  end
  
  def load()

  end
end