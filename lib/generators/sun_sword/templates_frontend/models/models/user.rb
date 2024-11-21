class Models::User < ApplicationRecord
  belongs_to :account, class_name: 'Models::Account', foreign_key: 'account_id'

  enum role: { owner: 'owner', contact: 'contact' }
end
