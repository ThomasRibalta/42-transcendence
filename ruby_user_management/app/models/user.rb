class User
  attr_accessor :id, :username, :email, :password, :role, :login_type, :active_at, :update_at, :delete_at, :created_at

  def initialize(id = nil, username = nil, email = nil,
                password = nil, role = nil, login_type = nil,
                active_at = nil, update_at = nil, delete_at = nil, created_at = nil)
    @id = id
    @username = username
    @email = email
    @password = password
    @role = role
    @login_type = login_type
    @active_at = active_at
    @update_at = update_at
    @delete_at = delete_at
    @created_at = created_at
  end
end