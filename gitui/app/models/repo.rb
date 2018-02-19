class Repo < ApplicationRecord
  validates :name, presence: true
end
