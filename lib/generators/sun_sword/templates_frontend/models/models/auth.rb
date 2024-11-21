class Models::Auth < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  belongs_to :account, class_name: 'Models::Account', foreign_key: 'account_id'
  belongs_to :user, class_name: 'Models::User', foreign_key: 'user_id'
end
