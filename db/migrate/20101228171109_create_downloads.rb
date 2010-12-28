class CreateDownloads < ActiveRecord::Migration
  def self.up
    create_table :downloads do |t|
      t.string :link  # the download link
      t.integer :user_id # one user has many downloads
      t.integer :type_id # hotfile, rapidshare, etc?
      
      t.timestamps
    end
  end

  def self.down
    drop_table :downloads
  end
end
