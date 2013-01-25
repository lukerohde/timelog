require 'Qt'
require 'json'
require 'securerandom'
require 'ruby-debug'
require 'net/http'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-migrations'
require './helpers.rb'
require './time_item.rb'
require './time_item_view.rb'
require './time_list.rb'
require './time_list_ws.rb'
require './time_list_view.rb'
require './task_item.rb'
require './task_item_ws.rb'
require './task_item_view.rb'
require './task_list.rb'
require './task_list_ws.rb'
require './logger_view.rb'
#require './data/time_item_db.rb'

#GC.disable

#debugger

app = Qt::Application.new(ARGV)

#taskList = TaskList.new('task.marshal')
taskList = TaskListWS.new()
timeList = TimeList.new('time.marshal', taskList)

loggerView = LoggerView.new(timeList, taskList)
loggerView.show()
app.exec()

taskList.save
timeList.save
