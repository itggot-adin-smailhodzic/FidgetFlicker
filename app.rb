class App < Sinatra::Base

	enable :sessions

	get '/' do
		slim :index
	end

	get '/register' do
		slim :register
	end

	get '/login' do
		slim :login
	end

	post '/register_user' do
		db = SQLite3::Database.new("database.db")

		username = params[:username]
		password = params[:password]

		password_digest = BCrypt::Password.create(password)


		# 'State' = 0; Offline. 'State' = 1; Online. 'State' = 2; Away.

		db.execute("INSERT INTO Users(username,password,state) VALUES(?,?,0)", [username,password_digest])
		redirect('/')
	end

	post '/login_user' do

		db = SQLite3::Database.new("database.db")

		username = params[:username]
		password = params[:password]

		id, username_verify, password_verify, state, score, highscore = db.execute("SELECT * FROM Users WHERE username = '#{username}'")[0]

		if password_verify != nil
			password_verify = BCrypt::Password.new(password_verify)
		else
			password_verify = ""
		end

		if username == username_verify && password_verify == password
			# Login successful
			session[:id] = id
			redirect('/profile/' + session[:id].to_s)
		else
			redirect('/error')
		end

	end

	post '/password_recovery' do
		
	end

	post '/accept_friend' do

		id = params[:table_id].to_i

		db = SQLite3::Database.new('database.db')
		db.execute("UPDATE Relations SET Relation_State = 1 WHERE ID = #{id}")

		redirect('/profile/' + session[:id].to_s)

	end
	post '/decline_friend' do

		id = params[:table_id].to_i

		db = SQLite3::Database.new('database.db')
		db.execute("DELETE FROM Relations WHERE ID = #{id}")

		redirect('/profile/' + session[:id].to_s)

	end
 
	get '/profile/:id' do

		id = params[:id].to_i

		if id != session[:id]
			redirect('/error')
		end

		session[:id] = id

		db = SQLite3::Database.new('database.db')

		result = db.execute("SELECT * FROM Relations WHERE (User_1 = #{session[:id]} OR User_2 = #{session[:id]})")

		# result_string = result.to_s

		# index = 0
		# values = []
		  
		# result_string.each_char do |i|
		#   if i == '>'[0] then
		# 	values << index + 1
		#   end
		#   index += 1
		# end

		var = 0 
		  
		slim(:menu, locals:{notes:result, id:id, i:var})
	end

	post '/friend_request' do

		db = SQLite3::Database.new("database.db")

		User_sender = session[:id]
		User_reciever = params[:request_user]

		User_reciever_compare = User_reciever.to_i

		if User_reciever_compare.to_s != User_reciever.to_s
			redirect('/error')
		end

		User_sender = User_sender.to_i
		User_reciever = User_reciever.to_i

		# 0 = Pending, 1 = Accepted, 2 = Denied, 3 = Blocked
		
		user_reciever_id_instance = db.execute("SELECT * FROM Users WHERE id = ?", [User_reciever])

		if user_reciever_id_instance.empty? == false # Checks if the user recipent is non-existant

			if User_sender < User_reciever
				db.execute("INSERT INTO Relations(User_1,User_2,Relation_State,User_Action) VALUES(?,?,0,?)", [User_sender, User_reciever, User_sender])
			elsif User_reciever < User_sender
				db.execute("INSERT INTO Relations(User_1,User_2,Relation_State,User_Action) VALUES(?,?,0,?)", [User_reciever, User_sender, User_sender])
			else
				redirect('/error')
			end
	
			redirect('/profile/' + session[:id].to_s)

		else

			redirect('/error')

		end

	end



end           
