class CreateRepos < ActiveRecord::Migration[5.1]
  def change
    create_table :repos do |t|
      t.string :name
      t.string :url
      t.string :owner

      t.timestamps
    end
  end
end
