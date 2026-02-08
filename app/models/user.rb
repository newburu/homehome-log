class User < ApplicationRecord
  devise :database_authenticatable, :rememberable, :omniauthable, omniauth_providers: %i[google_oauth2 twitter2]

  has_many :logs, dependent: :destroy

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
    end
  end

  def self.create_guest
    create!(
      provider: "guest",
      uid: SecureRandom.uuid,
      name: "Guest User",
      email: nil,
      password: Devise.friendly_token[0, 20]
    )
  end

  def email_required?
    false
  end

  def will_save_change_to_email?
    false
  end
end
