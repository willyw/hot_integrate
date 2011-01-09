class CreateDownloads < ActiveRecord::Migration
  def self.up
    create_table :downloads do |t|
      t.string :filename  # after download, fill this filename
      t.string :link  # the download link
      t.boolean  :status_download , :default => false
      t.integer :status_file , :default => 2 # 2 = unknown
      # 1 = alive
      # 0 = dead
      
      t.integer :user_id # one user has many downloads
      t.integer :type_id # hotfile, rapidshare, etc?
      #hotfile type == 1 
      
      t.timestamps
    end
  end

  def self.down
    drop_table :downloads
  end
end