
class TaskItemWS < TaskItem
  
  attr_accessor :name
  attr_accessor :notes
  attr_accessor :parent
  attr_accessor :estimate
  attr_accessor :status
  attr_accessor :time_items
  
  include Enumerable
  
  def initialize(name, notes)
    super(name, nil)
    @notes = notes # don't want notes= called, since it is used for note updating and writes to db
  end

  #WS time item method
  def to_json(*a)
   {
     'name' => self.name,
     'notes' => self.notes,
   }.to_json(*a)
  end

  def notes=(value)
    unless value.nil? || value == @notes
      #Debug.alert("notes: #{@notes}\nvalue: #{value}")
      @notes = value
      response = WS.put_data("/task/#{WS.encode(self.name)}", {"notes" => value.force_encoding('UTF-8')}.to_json)
    end 
  end
end

