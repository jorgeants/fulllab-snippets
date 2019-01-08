# Factorie
require 'rails_helper'

RSpec.describe User do
  before do
    create(:user)
  end

  it 'contains 4 roles' do
    expect(User.roles.size).to eq(4)
  end

  it 'returns user id' do
    expect(User.first.as_json.keys).to include('id')
  end

  it 'returns user first_name' do
    expect(User.first.as_json.keys).to include('first_name')
  end

  it 'returns user last_name' do
    expect(User.first.as_json.keys).to include('last_name')
  end

  it 'returns user email' do
    expect(User.first.as_json.keys).to include('email')
  end

  it 'returns user cpf' do
    expect(User.first.as_json.keys).to include('cpf')
  end

  it 'returns user role' do
    expect(User.first.as_json.keys).to include('role')
  end

  it 'returns created_at' do
    expect(User.first.as_json.keys).to include('created_at')
  end

  it 'does not return updated_at' do
    expect(User.first.as_json.keys).to_not include('updated_at')
  end

  context 'when superadmin' do
    context 'with associated restaurant' do
      let(:user) { build(:user, :superadmin) }

      it 'is valid' do
        expect(user.valid?).to be_truthy
      end
    end

    context 'without associated restaurant' do
      let(:user) { build(:user, :superadmin, restaurant: nil) }

      it 'is valid' do
        expect(user.valid?).to be_truthy
      end
    end
  end

  context 'when admin' do
    context 'with associated restaurant' do
      let(:user) { build(:user, :admin) }

      it 'is valid' do
        expect(user.valid?).to be_truthy
      end
    end

    context 'without associated restaurant' do
      let(:user) { build(:user, :admin, restaurant: nil) }

      it 'is NOT valid' do
        expect(user.valid?).to be_falsey
      end
    end
  end

  context 'when operator' do
    context 'with associated restaurant' do
      let(:user) { build(:user, :operator) }

      it 'is valid' do
        expect(user.valid?).to be_truthy
      end
    end

    context 'without associated restaurant' do
      let(:user) { build(:user, :operator, restaurant: nil) }

      it 'is NOT valid' do
        expect(user.valid?).to be_falsey
      end
    end
  end
end


# User Spec
require 'rails_helper'

RSpec.describe User do
  before do
    create(:user)
  end

  it 'contains 4 roles' do
    expect(User.roles.size).to eq(4)
  end

  it 'returns user id' do
    expect(User.first.as_json.keys).to include('id')
  end

  it 'returns user first_name' do
    expect(User.first.as_json.keys).to include('first_name')
  end

  it 'returns user last_name' do
    expect(User.first.as_json.keys).to include('last_name')
  end

  it 'returns user email' do
    expect(User.first.as_json.keys).to include('email')
  end

  it 'returns user cpf' do
    expect(User.first.as_json.keys).to include('cpf')
  end

  it 'returns user role' do
    expect(User.first.as_json.keys).to include('role')
  end

  it 'returns created_at' do
    expect(User.first.as_json.keys).to include('created_at')
  end

  it 'does not return updated_at' do
    expect(User.first.as_json.keys).to_not include('updated_at')
  end

  context 'when superadmin' do
    context 'with associated restaurant' do
      let(:user) { build(:user, :superadmin) }

      it 'is valid' do
        expect(user.valid?).to be_truthy
      end
    end

    context 'without associated restaurant' do
      let(:user) { build(:user, :superadmin, restaurant: nil) }

      it 'is valid' do
        expect(user.valid?).to be_truthy
      end
    end
  end

  context 'when admin' do
    context 'with associated restaurant' do
      let(:user) { build(:user, :admin) }

      it 'is valid' do
        expect(user.valid?).to be_truthy
      end
    end

    context 'without associated restaurant' do
      let(:user) { build(:user, :admin, restaurant: nil) }

      it 'is NOT valid' do
        expect(user.valid?).to be_falsey
      end
    end
  end

  context 'when operator' do
    context 'with associated restaurant' do
      let(:user) { build(:user, :operator) }

      it 'is valid' do
        expect(user.valid?).to be_truthy
      end
    end

    context 'without associated restaurant' do
      let(:user) { build(:user, :operator, restaurant: nil) }

      it 'is NOT valid' do
        expect(user.valid?).to be_falsey
      end
    end
  end
end


# User Controller Spec
require 'rails_helper'

RSpec.describe Api::UsersController, type: :api do
  let(:valid_user) {{
    first_name: 'Foo',
    last_name: 'Bar',
    email: 'foo@bar.com',
    cpf: CPF.generate(true),
    role: 'admin',
    restaurant_id: restaurant.id
  }}

  let(:invalid_user) {{
    first_name: '',
    last_name: '',
    email: '',
    cpf: '',
    role: ''
  }}

  let(:restaurant) { create(:restaurant) }

  describe '#index' do
    context 'with authenticated user' do
      before do
        authenticate_as_admin
        get '/api/users.json'
      end

      it 'returns success status' do
        expect(last_response.status).to eq(200)
      end

      it 'return users from same restaurant' do
        expect(last_response_body.size).to eq(1)
      end
    end

    context 'with unauthenticated user' do
      before do
        get '/api/users.json'
      end

      it 'returns unauthorized status' do
        expect(last_response.status).to eq(401)
      end
    end
  end

  describe '#show' do
    context 'with authenticated user' do
      before do
        authenticate_as_admin
        get '/api/users/1.json'
      end

      it 'returns success status' do
        expect(last_response.status).to eq(200)
      end

      it 'returns all fields' do
        expect(last_response_body.size).to eq(19)
      end

      it 'returns user id' do
        expect(last_response_body.keys).to include('id')
      end
    end

    context 'with unauthenticated user' do
      before do
        get '/api/users/1.json'
      end

      it 'returns unauthorized status' do
        expect(last_response.status).to eq(401)
      end
    end
  end

  describe '#create_user' do
    context 'authenticated as superadmin' do
      before { authenticate_as_superadmin }

      context 'with restaurant_id param' do
        let(:user_params) do
          {
            first_name: 'Foo',
            last_name: 'Bar',
            email: 'foo@bar.com',
            cpf: CPF.generate(true),
            role: 'admin',
            restaurant_id: restaurant.id
          }
        end

        before { post '/api/users/create_user.json', user: user_params }

        subject { last_response_body }

        it 'returns created status' do
          expect(last_response.status).to eq(201)
        end

        it 'has respond with the restaurant name' do
          expect(subject['restaurant_name']).to eq(restaurant.name)
        end
      end

      context 'without restaurant_id param' do
        let(:user_params) do
          {
            first_name: 'Foo',
            last_name: 'Bar',
            email: 'foo@bar.com',
            cpf: CPF.generate(true),
            role: 'admin',
          }
        end

        before { post '/api/users/create_user.json', user: user_params }

        it 'returns error status' do
          expect(last_response.status).to eq(400)
        end
      end
    end

    context 'authenticated as a non-superadmin' do
      before { authenticate_as_admin }

      context 'with restaurant_id param' do
        let(:user_params) do
          {
            first_name: 'Foo',
            last_name: 'Bar',
            email: 'foo@bar.com',
            cpf: CPF.generate(true),
            role: 'admin',
            restaurant_id: restaurant.id
          }
        end

        before { post '/api/users/create_user.json', user: user_params }

        subject { last_response_body }

        it 'returns created status' do
          expect(last_response.status).to eq(201)
        end

        it 'has respond with the restaurant name' do
          expect(subject['restaurant_name']).to_not eq(restaurant.name)
        end
      end

      context 'without restaurant_id param' do
        let(:user_params) do
          {
            first_name: 'Foo',
            last_name: 'Bar',
            email: 'foo@bar.com',
            cpf: CPF.generate(true),
            role: 'admin',
          }
        end

        before { post '/api/users/create_user.json', user: user_params }

        subject { last_response_body }

        it 'returns created status' do
          expect(last_response.status).to eq(201)
        end

        it 'has respond with the restaurant name' do
            expect(subject['restaurant_name']).to_not eq(restaurant.name)
        end
      end
    end

    context 'with authenticated user' do
      before do
        authenticate_as_admin
      end

      context 'with valid params' do
        it 'returns created status' do
          post '/api/users/create_user.json', user: valid_user
          expect(last_response.status).to eq(201)
        end

        it 'creates an user' do
          expect{ post '/api/users/create_user.json', user: valid_user }.to change{ User.count }.by(1)
        end
      end

      context 'with invalid parameters' do
        before do
          post '/api/users/create_user.json', user: invalid_user
        end

        it 'returns bad request status' do
          expect(last_response.status).to eq(400)
        end

        it 'returns error message' do
          expect(last_response_body.size).to be > 0
        end

        it 'returns error key' do
          expect(last_response_body.size).to be > 0
        end
      end
    end

    context 'with unauthenticated user' do
      before do
        post '/api/users/create_user.json', user: valid_user
      end

      it 'returns unauthorized status' do
        expect(last_response.status).to eq(401)
      end
    end
  end

  describe '#create_consumer' do
    context 'with valid params' do
      let(:consumer) {{
          first_name: 'First',
          last_name: 'Last',
          email: 'valid@email.com',
          password: 'password'
      }}

      it 'returns created status' do
        post '/api/users/create_consumer.json', user: consumer
        expect(last_response.status).to eq(200)
      end

      it 'changes user count' do
        expect{ post '/api/users/create_consumer.json', user: consumer }.to change{ User.count }
      end

      it 'assigns role consumer to the new user' do
        post '/api/users/create_consumer.json', user: consumer
        new_user = User.last
        expect(new_user.role).to eq('consumer')
      end
    end
  end

  describe '#update' do
    context 'with authenticated user' do
      before do
        authenticate_as_admin
      end

      context 'with valid params' do
        it 'returns created status' do
          put '/api/users/1.json', user: valid_user
          expect(last_response.status).to eq(200)
        end

        it 'does not change user count' do
          expect{ put '/api/users/1.json', user: valid_user }.to_not change{ User.count }
        end

        context 'with restaurant_id on params' do
          it 'associates with restaurant' do
            restaurant = create(:restaurant)
            operator = create(:user, :operator)

            put "/api/users/#{operator.id}.json", user: operator.attributes.merge({restaurant_id: restaurant.id})

            operator.reload

            expect(operator.restaurant).to eq(restaurant)
          end
        end
      end

      context 'with invalid parameters' do
        before do
          put '/api/users/1.json', user: invalid_user
        end

        it 'returns bad request status' do
          expect(last_response.status).to eq(400)
        end

        it 'returns error message' do
          expect(last_response_body.size).to be > 0
        end

        it 'returns error key' do
          expect(last_response_body.size).to be > 0
        end
      end
    end

    context 'with unauthenticated user' do
      before do
        put '/api/users/1.json', user: valid_user
      end

      it 'returns unauthorized status' do
        expect(last_response.status).to eq(401)
      end
    end
  end

  describe '#destroy' do
    context 'with authenticated user' do
      before do
        authenticate_as_admin
      end

      it 'returns no_content status' do
        delete '/api/users/1.json'
        expect(last_response.status).to eq(204)
      end

      it 'deletes an user' do
        expect{ delete '/api/users/2.json' }.to change{ User.count }.by(-1)
      end
    end

    context 'with unauthenticated user' do
      before do
        delete '/api/users/1.json'
      end

      it 'returns unauthorized status' do
        expect(last_response.status).to eq(401)
      end
    end
  end

  describe '#impersonate' do
    context 'with valid credentials' do
      before do
        @superadmin = authenticate_as_superadmin
        @admin = create(:user, :admin)
        post "/api/users/#{@admin.id}/impersonate"
      end

      it 'returns payload as the other user' do
        expect(last_response_body['user']).to eq(JSON.parse(@admin.to_json))
      end

      it 'returns true_user' do
        expect(last_response_body['true_user']).to eq(JSON.parse(@superadmin.to_json))
      end
    end

    context 'without superadmin credentials' do
      before do
        authenticate_as_admin
      end

      it 'returns unauthorized status' do
        other_admin = create(:user, :admin)
        post "/api/users/#{other_admin.id}/impersonate"
        expect(last_response.status).to eq(401)
      end
    end
  end

  describe '#stop_impersonating' do
    before do
      @superadmin = authenticate_as_superadmin
      post '/api/users/stop_impersonating'
    end

    it 'returns original superadmin as user' do
      expect(last_response_body['user']).to eq(JSON.parse(@superadmin.to_json))
    end

    it "doesn't return true_user" do
      expect(last_response_body).not_to include('true_user')
    end
  end
end
