require 'has_columns'

ActiveRecord::Base.class_eval do
  include ActiveRecord::HasColumns
end
