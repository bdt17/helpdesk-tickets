class User < ApplicationRecord
  # Devise modules...
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  after_create :set_default_role

  private

  def set_default_role
    self.role ||= 'client'
    save!
  end
end
