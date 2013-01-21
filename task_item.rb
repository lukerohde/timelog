class TaskItem
  attr_accessor :id
  attr_accessor :name
  attr_accessor :parent
  attr_accessor :estimate
  attr_accessor :status
  attr_accessor :notes
  attr_accessor :time_items
  
  include Enumerable
  
  def initialize(name)
    @name = name
    @id = SecureRandom.uuid
    @time_items = []
  end
  
  def each
    @time_items.each { |ti| yield ti }
  end
  
  def addTime(timeItem)
    @time_items << timeItem 
  end
  def removeTime(timeItem)
    @time_items.delete_if { |ti| ti == timeItem }
  end
  
  def removeAllTime()
    @time_items.clear
  end
    
  def marshal_dump
    [@name, @notes]
  end
  
  def marshal_load array
    @name, @notes = array
  end
end