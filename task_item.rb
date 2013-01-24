DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/timelog.sqlite3")

class TaskItem
  include DataMapper::Resource #DB time items

  property :name, Text, :required => true, :key => true
  property :notes, Text
  attr_accessor :parent
  attr_accessor :estimate
  attr_accessor :status
  attr_accessor :time_items
  
  include Enumerable
  
  def initialize(name, notes)
    self.name = name
    self.notes = notes
    #@id = SecureRandom.uuid
    @time_items = []
  end
  
  def setup
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
   
  # disk time item methods
  def marshal_dump
    [@name, @notes]
  end
  
  def marshal_load array
    @name, @notes = array
  end
  
  #WS time item method
  def to_json(*a)
   {
     'name' => self.name,
     'notes' => self.notes,
   }.to_json(*a)
  end

  #def notes=(value)
  #  @notes = value
  #  response = WS.http.request_put("/task/#{WS.encode(self.name)}", {"notes" => value}.to_json)
  #end
end

DataMapper.finalize
TaskItem.auto_upgrade!

