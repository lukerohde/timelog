DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/timelog.sqlite3")

class TaskItem
  include DataMapper::Resource #DB task items

  property :name, Text, :required => true, :key => true
  property :notes, Text
  
  #WS time item method
  def to_json(*a)
   {
     'name' => self.name,
     'notes' => self.notes,
   }.to_json(*a)
  end
end

DataMapper.finalize
TaskItem.auto_upgrade!
