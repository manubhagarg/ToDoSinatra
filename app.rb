require 'sinatra'
require 'data_mapper'

DataMapper.setup(:default, "sqlite:///#{Dir.pwd}/data.db")

set :sessions, true
set :bind, '0.0.0.0'

class User
    include DataMapper::Resource
    property :id, Serial
    property :email, Text
    property :password, Text
    property :name, Text
end

class Task
	include DataMapper::Resource
    property :id, Serial
    property :content, String
    property :done, Boolean
    property :important, Boolean
    property :urgent, Boolean
    property :user_id, Integer
end

DataMapper.finalize
User.auto_upgrade!
Task.auto_upgrade!

 
get '/' do
    user = nil
    if session[:user_id]
        user = User.get(session[:user_id])
    else
        redirect '/signin'
    end

    tasks = Task.all(:user_id => user.id)
    erb :index, locals: {user: user, tasks: tasks}
end

get '/signup' do
    erb :signup
end

post '/register' do
    name = params[:name]
    email = params[:email]
    password = params[:password]

    user = User.all(:email => email).first

    if user
        redirect '/signup' 
    else
        user = User.new
        user.email = email
        user.password = password
        user.name = name
        user.save # user_id generated on saving
        session[:user_id] = user.id
        redirect '/'
    end
end

post '/logout' do
    session[:user_id] = nil
    redirect '/'
end

get '/signin' do
    erb :signin
end

post '/signin' do
    email = params[:email]
    password = params[:password]
    
    user = User.all(:email => email).first

    if user
        if user.password == password
            session[:user_id] = user.id
            redirect '/'
        else
            redirect '/signin'
        end
    else
        redirect '/signup'
    end

    redirect '/'
end


post '/add_task' do
    content = params[:content]
    task = Task.new
    task.content = content
    task.user_id = session[:user_id]
    task.done = false
    task.important = false
    task.urgent = false
    task.save
    redirect '/'
end
 
post '/toggle_task' do
    task_id = params[:task_id]
    task = Task.get(task_id)
    if task.user_id == session[:user_id]
        task.done = !task.done
        task.save
    end
    redirect '/'
end

post '/important_task' do
	task_id = params[:task_id]
	task = Task.get(task_id)
    if task.user_id == session[:user_id]
	   task.important = !task.important
	   task.save
    end
	redirect '/'
end

post '/urgent_task' do
	task_id = params[:task_id]
	task = Task.get(task_id)
    if task.user_id == session[:user_id]
	   task.urgent = !task.urgent
	   task.save
    end
	redirect '/'
end

post '/delete_task' do 
    task = Task.get(params[:delete])
    task.destroy
    redirect '/'
end
