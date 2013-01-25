require 'rubygems'
require 'sinatra'
require 'json'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-migrations'
require './task_item_db.rb'
require './time_item_db.rb'

get '/tasks' do
  data = []
  data = TaskItem.all.each do  |ti| 
    data << ti
  end
  if data.nil? then 
    status 404
  else
    status 200
    body(data.to_a.to_json)
  end
end

get '/task/:name' do
  msg = "getting task: #{params[:name]}"
  data = TaskItem.get(params[:name])
  if data.nil? then
    status 404
    puts "failed #{msg}"
  else
    status 200
    body(data.to_json) 
    puts "succeeded #{msg}"
  end
end

# PUT selected over POST for update and create
# because we have the natural key and know the
# url so PUT's idempotence is a better fit
put '/task/:name' do
  data = JSON.parse(request.body.read)
  
  if params[:name].nil? then
    status 400
  else
    task = TaskItem.get(params[:name])
    if task.nil?
      task = TaskItem.new( params[:name] )
      task.notes = data['notes'] unless data['notes'].nil?
      msg = "creating task: #{params[:name]}"
    else
      task.notes = data['notes'] unless data['notes'].nil?
      msg = "updating task: #{params[:name]}"
    end
    begin
    if !task.save then
      status 500
      puts "failed #{msg}"
    else
      status 200
      puts "succeeded #{msg}"
    end
    rescue Exception => err
      puts err
    end
    
    status 200
  end
end

delete '/task/:name' do
  puts "**** delete task #{params[:name]}"
  task = TaskItem.get(params[:name])
  if task.nil? then
    status 404
  else
    if task.destroy then
      status 200
    else
      status 500
    end
  end
end


get '/times' do
  data = []
  data = TimeItem.all.each do  |ti| 
    data << ti
  end
  if data.nil? then 
    status 404
  else
    status 200
    body(data.to_a.to_json)
  end
end

