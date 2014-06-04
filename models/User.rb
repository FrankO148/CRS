load 'config/database.rb'

class User < ActiveRecord::Base
	validates :name,:lastname,:password,:password_confirmation,:mail,:cel,:key,  presence: {message: 'No puede estar en blanco'}
	validates :password, confirmation: true, length: {minimum: 6} 
	validates :mail, :cel, uniqueness: {message: 'Ya existe'}
	validates :mail , format: {with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/, message: "Ingrese un mail valido"}
	validates :cel , format: {with: /261(2|3|4|5|6)[0-9]{6}/, message:"Debe ingresar su numero de la forma especificada ejemplo: 2615000000"} 
	validates :key, format: {with: /\A[A-Z][A-Z][A-Z]\z/, message: "Solo debe ingresar 3 letras en mayuscula" } 
	validates_each :key do |record,attr,value|
		if (value[0]==value[1] || value[0]==value[2] || value[1]==value[2])
			record.errors.add attr , 'Debe tener 3 letras diferentes'
		end
	end
	before_save :hash_pass

 	
	def self.generate_matrix (id)
		current_user=User.find(id)	
		letters=('A'..'Z').to_a
		secret_number=Array.new(3)
#create the matrix used to send SMS	
		matrix=Array.new(10){Array.new(3)}
#create an array to push each selected letter
		selected_letters=Array.new(30)
		i=0
		10.times do
			j=0
			3.times do
				selected_letter=nil
#I see that each selected letter doesn't match with the secret key letters
				while	 selected_letter == nil || selected_letter == current_user.key[0] || selected_letter == current_user.key[1] || selected_letter == current_user.key[2]	
					position=rand(0..25)
					selected_letter=letters.fetch(position)
				end
				selected_letters.push(selected_letter)
				matrix[i][j]=selected_letter
				j=j+1
			end
			i=i+1	
		end
		User.insert_user_key(current_user,matrix)
	end
=begin
	Una vez que tengo la matriz con las letras coloco las perenecientes a la palabra secreta 	
=end
	def self.insert_user_key (current_user, matrix)		
		secret_key=User.generate_key
		located_letters_index=Array.new() 
		i=0
		3.times do
			3.times do
				j=0
#me fijo si ya hay una letra de la clave, si hay  guardo la posicion de la letra y existente
				if matrix[secret_key[i]].include?(current_user.key[j])
					located_letters_index << matrix[secret_key[i]].index(current_user.key[j]) 
				end
				j=j+1	
			end
#si no hay palabras de la clave secreta que coincidan inserto la letra aleatoriamente , si hay coincidencia cuido de no pisar la letra anteriormente insertada 
			if located_letters_index.empty?
				matrix[secret_key[i]][rand(0..2)]=current_user.key[i]
			else
				h=rand(0..2)
				while located_letters_index.include?(h)
					h=rand(0..2)
				end
				matrix[secret_key[i]][h]=current_user.key[i]
			end	
			i=i+1
		end	
		number_secret=(secret_key[0]).to_s + (secret_key[1]).to_s + (secret_key[2]).to_s
		data={matrix: matrix, number_secret: number_secret}
		return data	
	end
	def self.generate_key
		secret_key=Array.new()
		3.times do
			secret_key << rand(0..9)
		end
		return secret_key
	end

	def send_code
		require 'net/http'
		code=User.generate_matrix(self.id)
		i=0
		message=""
		code[:matrix].each do |vector|
			
			message=message+" #{i}-"
			vector.each do | letter|
				message=message+"#{letter}" 
			end
			if i%2!=0
                                message=message+":"
                        end
			i=i+1		
		end
		postData = Net::HTTP.post_form(URI.parse('http://127.0.0.1/messages'), {
			'message[number]'=>"#{self.cel}",
			'message[content]'=>"#{message}"
		})
		return code[:number_secret]
	end
	def hash_pass
		require 'digest/sha2'
		self.password= (Digest::SHA512.new << self.password).to_s
	end
	
end

