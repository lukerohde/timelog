DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/timelog.sqlite3")

class TimeItem
  include DataMapper::Resource #DB time items
  storage_names[:legacy] = 'time_items'
  property :id, Serial, :required => true, :key => true
  property :task, Text, :required => true
  property :time_secs, Integer, :required => true
  property :start_time, DateTime, :required => true
  
  def to_json(*a)
   {
     'id' => self.id,
     'task' => self.task,
     'time_secs' => self.time_secs,
     'start_time' => self.start_time,
   }.to_json(*a)
  end
end

DataMapper.finalize
TimeItem.auto_upgrade!
