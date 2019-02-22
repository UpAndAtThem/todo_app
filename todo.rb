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
  elsif session[:lists].any? { |list| list[:name] == list_name}
    "List name must be unique"
  end
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
  @list = @lists[@params['list_id'].to_i]
  erb :single_list, layout: :layout
end

post "/lists/:list_id" do
  
end

get "/lists" do
  erb :lists, layout: :layout
end



