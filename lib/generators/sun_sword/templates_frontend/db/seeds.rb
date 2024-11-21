account = Models::Account.first_or_create(name: 'KOTAROISME')
user =  Models::User.create(full_name: 'Kotaro Minami', account_id: account.id, role: 'owner')
Models::Auth.create(email: 'kotaroisme@gmail.com', password: 'blankblank', password_confirmation: 'blankblank', account_id: account.id, user_id: user.id)
