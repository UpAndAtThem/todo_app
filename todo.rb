require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"
require "pry"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  @lists = session[:lists]
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

def list_name_error(list_name)
  if !(1..100).cover? list_name.size
    "List name must be between 1 and 100 characters"
  elsif session[:lists].any? { |list| list[:name] == list_name }
    "List name must be unique"
  end
end

def todo_name_error(todo)
  if !(1..100).cover? todo.size
    "Todo must be between 1 and 100 characters"
  end 
end

def to_bool(str)
  str == 'true'
end

def uncompleted_todos_count list
  total_todos = list[:todos].count.to_s
  remaining = list[:todos].map { |todo| todo[:completed] }.count(false).to_s
  remaining + " / " +total_todos
end

def todos_completed?(list)
  has_todos?(list[:todos]) &&
  all_todos_complete?(list[:todos])
end

def all_todos_complete?(todos)
  todos.all? { |todo| todo[:completed] }
end

def has_todos?(todos)
  todos.count > 0
end

get "/lists" do
  erb :lists, layout: :layout
end

post "/lists" do
  list_name = @params['list_name'].strip
  error = list_name_error(list_name)

  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << {name: @params["list_name"], todos: []}
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

get "/lists/new" do
  erb :new_list, layout: :layout
end

get "/lists/:list_id" do
  @list_id = params['list_id'].to_i
  @list = @lists[@list_id]
  erb :single_list, layout: :layout
end

post "/lists/:list_id/edit_list" do
  error = list_name_error @params['list_name'].strip

  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    list = session[:lists][@params['list_id'].to_i]
    list[:name] = @params['list_name']
    session[:success] = "The list has been renamed."
    redirect "/lists/" + @params['list_id']
  end
end


get "/lists/:list_id/edit_list" do
  @list = @lists[@params["list_id"].to_i]
  erb :edit_list, layout: :layout
end

# deletes a list
post "/lists/:list_id/delete" do
  session["success"] = "The list has been deleted" 
  @deleted = @lists.delete_at params['list_id'].to_i
  redirect "/lists"
end

# add a new todo to a list
post "/lists/:list_id/todos" do
  @list_id = params['list_id'].to_i
  @list = session[:lists][@list_id]
  @new_todo = params['todo'].strip

  error = todo_name_error @new_todo

  if error
    session[:error] = error
    erb :single_list, layout: :layout
  else
    @list[:todos] << { name: @new_todo, completed: false }
    session[:success] = "The todo item has been added."
    redirect "/lists/#{params['list_id']}"
  end
end

post "/lists/:list_id/todos/:todo_id/delete_todo" do
  @list_id = params['list_id'].to_i
  @todo_id = params['todo_id'].to_i

  @lists[@list_id][:todos].delete_at @todo_id
  session[:success] = "The todo item has been deleted"
  redirect "/lists/" + params['list_id'] 
end

post "/lists/:list_id/todos/:todo_id/complete_todo" do
  @list_id = params['list_id'].to_i
  @todo_id = params['todo_id'].to_i

  @todo = @lists[@list_id][:todos][@todo_id]
  @todo[:completed] = to_bool params['completed']
  session[:success] = "The todo has been updated"
  redirect "/lists/#{params['list_id']}"
end

post "/lists/:list_id/todos/mark_all_complete" do
  @list_id = params['list_id'].to_i
  @lists[@list_id][:todos].each { |todo| todo[:completed] = true }
  session[:success] = "All todos have been completed"
  redirect "/lists/#{@list_id}"
end
