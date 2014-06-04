require 'sinatra'
require 'rack-flash'
require 'digest/sha2'
load 'models/User.rb'

enable :sessions
use Rack::Flash


get '/' do
	if session[:state] == 1
		redirect to('/code')
	elsif session[:state] == 2
		redirect to('/index')
	else
		redirect to('/login')
	end	
end

get '/login' do
	if session[:state] 
		redirect to('/')
	else
		erb :login
	end	
end

post '/login' do
	if session[:state]
		redirect to('/')
	else
		pass_hash= Digest::SHA2.new << params[:password]
		if u1= User.find_by_mail_and_password(params[:mail],pass_hash.to_s)
#Si el usuario puede entrar con contraseña y password cambio el estado a 1
			session[:state]=1
			session[:user]=u1
			session[:code]=session[:user].send_code
			session[:attempt]=0	
			redirect to('/')	
		else
			redirect to('/') 
		end
	end	  
end
get '/send_code' do
	if session[:state] != 1
                flash[:notice]="Debe loguearse"
                redirect to('/')
        elsif
                session[:code]=session[:user].send_code
		flash[:notice]="Nuevo codigo enviado"	
                redirect to('/code')
        end

 	
end
get '/code' do
	if session[:state] != 1 
		flash[:notice]="Debe loguearse"
		redirect to('/')
	end	
		erb :code
end

post '/code' do
	if session[:state] != 1 
		flash[:notice]="Debe loguearse"	
                redirect to('/')
        elsif
		
			if params[:code]==session[:code]
				session[:code]=""
				session[:state]=2
				redirect to('/index')
			else
				flash[:notice]="La clave ingresada es incorrecta se enviara otra clave a su celular."
				session[:code]=session[:user].send_code	
				redirect to('/code')
			end
			
	end
end

get '/signup' do
	if session[:state]
                redirect to('/')
        else
		erb :signup
	end

end

post '/signup' do
	if session[:state]
		redirect to('/')
	else
		user1=User.new(params)
		if user1.valid?
			if(user1.save())
			
				flash[:notice]="El usuario fue creado con exito"
				redirect to('/login')
			
			else
			
				flash[:notice]="No pudo crearse el usuario"
				redirect to('/login')
			end	
		else
			flash[:notice]=" "
			user1.errors.full_messages.each do |message|
				flash[:notice]=flash[:notice]+", #{message}\n"
				
			end
			
			redirect to('/signup')
		end
	end		
end
get '/index' do
	if session[:state] != 2
		flash[:notice]="Debe loguearse"
		redirect to('/')
	else
		erb :index	
	end

end

