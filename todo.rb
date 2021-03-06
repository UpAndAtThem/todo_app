require "sinatra"
require "sinatra/reloader" #if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  @lists = session[:lists]
  session[:lists] ||= []
end

helpers do
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
    remaining = list[:todos].count { |todo| todo[:completed] }.to_s
    remaining + " / " + total_todos
  end
  
  def list_completed?(list)
    has_todos?(list[:todos]) && all_todos_complete?(list[:todos])
  end

  def sort_lists(lists, &block)
    complete, incomplete = lists.partition { |list| list_completed? list }

    incomplete.each { |list| yield list }
    complete.each { |list| yield list }
  end

  def sort_todos(list, &block)
    complete, incomplete = list[:todos].partition { |todo| todo[:completed] }

    incomplete.each { |todo| yield todo, list[:todos].index(todo) }
    complete.each { |todo| yield todo, list[:todos].index(todo) }
  end

  def load_list(list_id)
    list = @lists.detect { |list| list[:id] == list_id }
    return list if list

    session[:error] = "The desired list could not be found"
    redirect "/lists"
  end
end

def all_todos_complete?(todos)
  todos.all? { |todo| todo[:completed] }
end

def has_todos?(todos)
  todos.count > 0
end

get "/" do
  redirect "/lists"
end

get "/lists" do
  erb :lists, layout: :layout
end

def next_list_id(lists)
  max = lists.map{ |list| list[:id] }.max || 0
  max + 1
end

post "/lists" do
  @list = @params['list_name'].strip
  error = list_name_error(@list)

  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    id = next_list_id @lists
    session[:lists] << {id: id, name: @params["list_name"], todos: []}
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

get "/lists/new" do
  erb :new_list, layout: :layout
end

get "/lists/:list_id" do
  @list = load_list params['list_id'].to_i
  @list_id = params['list_id'].to_i

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
  @list = load_list params['list_id'].to_i
  erb :edit_list, layout: :layout
end

# deletes a list
post "/lists/:list_id/delete" do
  @deleted = @lists.delete_if { |list| list[:id] == params['list_id'].to_i }

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session["success"] = "The list has been deleted" 
    redirect "/lists"
  end
end

def next_todo_id(todos)
  max = todos.map { |todo| todo[:id] }.max || 0
  max + 1
end

# add a new todo to a list
post "/lists/:list_id/todos" do
  @list_id = params['list_id'].to_i
  @list = session[:lists].detect{ |list| list[:id] == @list_id }
  
  @new_todo = params['todo'].strip
  error = todo_name_error @new_todo

  if error
    session[:error] = error
    erb :single_list, layout: :layout
  else
    id = next_todo_id(@list[:todos])
    @list[:todos] << { id: id, name: @new_todo, completed: false }

    session[:success] = "The todo item has been added."
    redirect "/lists/#{params['list_id']}"
  end
end

post "/lists/:list_id/todos/:todo_id/delete_todo" do
  @list_id = params['list_id'].to_i
  @todo_id = params['todo_id'].to_i

  @list = @lists.detect { |list| list[:id] == @list_id }
  @list[:todos].delete_if { |todo| todo[:id] == @todo_id }

  if env["HTTP_X_REQUESTED_WITH"] == 'XMLHttpRequest'
    status 204
  else
    session[:success] = "The todo item has been deleted"
    redirect "/lists/" + params['list_id'] 
  end
end

post "/lists/:list_id/todos/:todo_id/complete_todo" do
  @list_id = params['list_id'].to_i
  @todo_id = params['todo_id'].to_i
  @list =  @lists.detect { |list| list[:id] == @list_id}
  @todo = @list[:todos].detect { |todo| todo[:id] == @todo_id}

  @todo[:completed] = to_bool params['completed']
  session[:success] = "The todo has been updated"
  redirect "/lists/#{@list_id}"
end

post "/lists/:list_id/todos/mark_all_complete" do
  @list_id = params['list_id'].to_i
  @lists[@list_id][:todos].each { |todo| todo[:completed] = true }
  session[:success] = "All todos have been completed"
  redirect "/lists/#{@list_id}"
end
