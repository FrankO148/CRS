require 'active_record'
require 'mysql2'

ActiveRecord::Base.establish_connection(
adapter: 'mysql2',
database: 'RSservice',
username: 'cloudfile',
password: 'cloudfile',
host: '127.0.0.1'

)
