require 'Qt'
require 'json'
require 'securerandom'
require 'ruby-debug'
require './helpers.rb'
require './time_item.rb'
require './time_list.rb'
require './time_list_view.rb'
require './time_item_view.rb'
require './task_item.rb'
require './task_list.rb'
require './task_item_view.rb'
require './logger_view.rb'

#GC.disable

#debugger

app = Qt::Application.new(ARGV)

taskList = TaskList.new('task.marshal')
timeList = TimeList.new('time.marshal', taskList)

loggerView = LoggerView.new(timeList, taskList)
loggerView.show()
app.exec()

taskList.save
timeList.save
