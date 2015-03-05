require_relative 'common.rb'

module FormActions
  include Pushfour::Common
  extend self

  def register(raw_name, raw_password1, raw_password2)
    errors = []

    name = sanitized_name(raw_name)

    errors << 'Name contained illegal characters' if name != raw_name
    errors << 'Name cannot be empty' unless name and name.size > 0
    errors << 'Must enter a password' unless password
    errors << 'Passwords must match' unless password == password2

    errors << "Name '#{name}' is in use" if name and name_in_use?(name)

    {errors: errors, name: name}
  end
end
