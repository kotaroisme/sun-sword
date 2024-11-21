class Models::Account < ApplicationRecord
  has_many :auths, foreign_key: 'account_id', class_name: 'Models::Auth'
  has_many :users, foreign_key: 'account_id', class_name: 'Models::User'
end
