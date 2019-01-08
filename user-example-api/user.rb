# User Model
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  enum role: [:superadmin, :admin, :operator, :consumer]

  belongs_to :restaurant, optional: true # Admin and Operator only
  has_many :bills
  has_many :orders, through: :bills
  has_many :credit_cards
  has_many :user_photos, :dependent => :destroy

  accepts_nested_attributes_for :user_photos, :allow_destroy => true

  validate :roles_must_have_restaurant
  validates :api_id, uniqueness: true
  validate :cpf_valid
  validates :cpf, uniqueness: { scope: :role }, if: '!cpf.blank? && role == "consumer"'
  validate :consumer_profile_is_completed, on: :update
  validate :valid_date, on: :update
  validate :valid_birth_date_minimal, on: :update

  def consumer_profile_is_completed
    if consumer?
      errors.add(:first_name, :blank) if first_name.blank?
      errors.add(:last_name, :blank) if last_name.blank?
      errors.add(:email, :blank) if email.blank?
      errors.add(:cpf, :blank) if cpf.blank?
      errors.add(:birth_date, :invalid) if birth_date.blank?
      errors.add(:phone, :blank) if phone.blank?
    end
  end

  def valid_date
    unless birth_date.nil? || birth_date.blank?
      errors.add(:birth_date, :invalid) if !Date.valid_date?(birth_date.year, birth_date.month, birth_date.day)
    end
  rescue ArgumentError
    errors.add(:birth_date, :invalid)
  end

  def valid_birth_date_minimal
    unless birth_date.nil? || birth_date.blank?
      errors.add(:birth_date, :no_rate_age) if birth_date > 14.years.ago.to_date
    end
  rescue ArgumentError
    errors.add(:birth_date, :invalid)
  end

  def roles_must_have_restaurant
    if (admin? || operator?) && restaurant.nil?
      errors.add(:restaurant_id, 'must be associated')
    end
  end

  def cpf_valid
    unless cpf.nil? || cpf.blank?
      errors.add(:cpf, :invalid) unless CPF.valid?(cpf)
    end
  end

  def as_json(options = {})
    options[:only] ||= [
      :id, :first_name, :last_name, :email, :cpf, :role, :restaurant_id, :phone, :birth_date, :zipcode, :created_at,
      :api_id, :api_secret, :blocked
    ]
    options[:methods] ||= [:has_completed_profile, :has_credit_card, :restaurant_name, :has_facebook_auth, :avatar_url]
    super(options)
  end

  def name
    "#{first_name} #{last_name}"
  end

  def has_facebook_auth
    !facebook_id.blank?
  end

  # Overrides Devise method
  # Facebook users won't need password
  def password_required?
    super unless has_facebook_auth
  end

  def has_credit_card
    self.credit_cards.enabled.length > 0
  end

  def set_api_id_and_secret
    self.api_id = SecureRandom.urlsafe_base64
    self.api_secret = SecureRandom.urlsafe_base64(50)
  end

  def active_for_authentication?
    super && !self.blocked
  end

  def inactive_message
    !self.blocked ? super : :blocked
  end

  def has_completed_profile
    (!self.first_name.blank? && !self.last_name.blank? && !self.email.blank? && !self.cpf.blank? && !self.birth_date.blank? && !self.phone.blank?)
  end

  def avatar_url
    self.user_photos.last.avatar.url(:small) if self.user_photos.last
  end
end


# User Controller
class Api::UsersController < Api::BaseController
  before_action :set_user, only: [:show, :update, :destroy, :impersonate]
  skip_before_action :authenticate_user!, only: :create_consumer

  # GET /api/users
  def index
    users = UsersService.index(current_user, params[:start_date_time], params[:end_date_time])
    render json: users
  end

  # GET /api/users/1
  def show
    render json: @user
  end

  # GET /api/me
  def me
    render json: current_user
  end

  # POST /api/users/create_user
  def create_user
    generated_password = Devise.friendly_token.first(10)

    data = user_params.merge({ password: generated_password })
    unless current_user.superadmin?
      data.merge!({ restaurant_id: current_user.restaurant_id })
    end

    @user = User.new(data)
    @user.set_api_id_and_secret
    if @user.save
      UserMailer.welcome_user(@user).deliver_later
      UserMailer.notify_superadmins(@user).deliver_later
      User.send_reset_password_instructions({ email: @user.email })

      render json: @user, status: :created
    else
      log_modal_errors @user
      render json: @user.errors, status: :bad_request
    end
  end

  # POST /api/users/create_consumer
  def create_consumer
    @consumer = User.new(consumer_params)
    @consumer.role = :consumer
    @consumer.set_api_id_and_secret
    if @consumer.save
      UserMailer.welcome_user(@consumer).deliver_later
      UserMailer.notify_superadmins(@consumer).deliver_later

      sign_in(:user, @consumer)

      json = { token: JWTWrapper.encode({ user_id: @consumer.id }), user: @consumer }.to_json
      render json: json, status: status, content_type: 'application/vnd.api+json'
    else
      log_modal_errors @consumer
      message = @consumer.errors.full_messages.join(', ')
      email_taken = @consumer.errors.added? :email, :taken
      key = email_taken ? 'email_taken' : 'invalid_parameters'
      render json: { message: message, key: key }, status: :bad_request
    end
  end

  # PATCH /api/users/1
  # PUT /api/users/1
  def update
    if @user.update_attributes(user_params)
      render json: @user
    else
      log_modal_errors @user
      render json: @user.errors.full_messages, status: :bad_request
    end
  end

  # DELETE /api/users/1
  def destroy
    if @user.destroy
      head :no_content
    else
      log_modal_errors @user
      render json: { message: 'Unable to destroy', key: 'unable_to_destroy' }, status: :bad_request
    end
  end

  # POST /api/users/1/impersonate
  def impersonate
    unless current_user.superadmin?
      return render json: { message: 'Not authorized', key: 'not_authorized' }, status: :unauthorized
    end

    impersonate_user(@user)
    status = :created
    json = { token: JWTWrapper.encode({ user_id: current_user.id, true_user_id: true_user.id }), user: current_user, true_user: true_user }.to_json
    render json: json, status: status, content_type: 'application/vnd.api+json'
  end

  # POST /api/users/stop_impersonating
  def stop_impersonating
    stop_impersonating_user
    json = { token: JWTWrapper.encode({ user_id: real_user.id }), user: real_user }.to_json
    render json: json, content_type: 'application/vnd.api+json'
  end

  # GET /api/users/report?status=news&period=weekly
  def report
    users = UsersService.report(current_user, params[:period], params[:status])
    render json: users
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(
        :first_name,
        :last_name,
        :email,
        :cpf,
        :role,
        :restaurant_id,
        :phone,
        :birth_date,
        :zipcode,
        :blocked,
        user_photos_attributes: [
          :avatar,
          :user_id
        ]
      )
    end

    def consumer_params
      params.require(:user).permit(
        :first_name,
        :last_name,
        :email,
        :password,
        :phone,
        :birth_date,
        :facebook_id,
        :facebook_link,
        :facebook_picture_url,
        :facebook_cover_url,
        :facebook_gender,
        :facebook_timezone,
        :facebook_age_min,
        :facebook_age_max,
        :facebook_verified,
        user_photos_attributes: [
          :avatar,
          :user_id
        ]
      )
    end
end


# User Service
class UsersService

  def self.index(user, *args)
    if args[0] && args[1]
      if args[0]
        start_date_time_parsed = DateTime.parse(args[0])
      end
      if args[1]
        end_date_time_parsed = DateTime.parse(args[1])
      end
    end

    if user.superadmin?
      if args[0] && args[1]
        users = User.where(created_at: start_date_time_parsed..end_date_time_parsed).order(created_at: :desc)
      else
        users = User.order(created_at: :desc).all
      end
    elsif user.admin?
      if args[0] && args[1]
        users = User.where(restaurant_id: user.restaurant_id).where(created_at: start_date_time_parsed..end_date_time_parsed).order(created_at: :desc).all
      else
        users = User.where(restaurant_id: user.restaurant_id).order(created_at: :desc).all
      end
    else
      users = [user]
    end

    return users
  end

  def self.report(user, *args)
    if user.superadmin?
      users = User.consumer.order(created_at: :desc)

      if args[0] && args[1]
        period = args[0] || :weekly
        status = args[1] || :news

        users = select_period(users, period) if status === "news"

        case status
        when "news"
          users = users
        when "actives"
          users = users.select{ |u| u.iugu_credit_cards.enabled.size > 0 } # filter this?
          users = users.select{ |u| select_period(u.bills, period).closed.size > 0 }
        when "remnants"
          users = users.select{ |u| u.iugu_credit_cards.enabled.size > 0 } # filter this?
          users = users.select{ |u| select_period(u.bills, period).closed.size > 1 }
        end
      else
        users = users.order(created_at: :desc).all
      end

      return users
    end
  end

  def self.select_period(resource, period)
    today = DateTime.now.beginning_of_day

    case period
    when "weekly"
      result = resource.where(created_at: (today - 1.week)..today)
    when "monthly"
      result = resource.where(created_at: (today - 1.month)..today)
    when "semesterly"
      result = resource.where(created_at: (today - 6.month)..today)
    when "yearly"
      result = resource.where(created_at: (today - 1.year)..today)
    end
    return result
  end
end
