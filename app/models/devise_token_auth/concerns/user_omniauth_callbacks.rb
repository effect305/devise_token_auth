module DeviseTokenAuth::Concerns::UserOmniauthCallbacks
  extend ActiveSupport::Concern

  included do
    validates :email, presence: true, email: true, if: Proc.new { |u| u.provider == 'email' }
    validates :phone, presence: true,
              format: { with: /\A\+\d+\z/, message: 'only international phone format allowed' },
              if: Proc.new { |u| u.provider == 'phone' }
    validates_presence_of :uid, if: Proc.new { |u| u.provider != 'phone' }

    # only validate unique emails among email registration users
    validate :unique_phone_user, on: :create
    validate :unique_email_user, on: :create

    # keep uid in sync with email
    before_save :sync_uid
    before_create :sync_uid
  end

  protected

  # only validate unique email among users that registered by email
  def unique_email_user
    if provider == 'email' && self.class.where(provider: 'email', email: email).count > 0
      errors.add(:email, :taken)
    end
  end

  # only validate unique phone among users that registered by phone
  def unique_phone_user
    if provider == 'phone' && self.class.where(provider: 'phone', phone: phone).count > 0
      errors.add(:phone, :taken)
    end
  end

  def sync_uid
    self.uid = email if provider == 'email'
  end
end
