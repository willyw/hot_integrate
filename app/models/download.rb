# for hotfile
require 'httparty'
require 'pp'
require 'digest/md5'
require 'fileutils'

require 'net/http'
# end


# interface == check_#{hotfile, rapidserve, fileserve}
class Download < ActiveRecord::Base
  belongs_to :user
  
  #include Dutil  << if this in-class implementation is successful, implement it as Dutil
  
  LINK_MATCHER = {1 => /^(http:\/\/)?hotfile.com/, 
                  2 => /^(http:\/\/)?fileserve.com/,
                 3 => /^(http:\/\/)?fileserve.com/}
  
  def self.create_batch( current_user, unfiltered_links )
    download_array = []
    for link in Download.filter_links( unfiltered_links ) 
      # link_type = Download.deduce_type( link )
      link_type_id = Download.deduce_type( link )
      download = current_user.downloads.create( :link => link, :type_id => link_type_id )
      download_array << download
    
      # download.assign_validity  # << delayed job, with the highest priority
      download.delay.process_download
      
      
      # download.execute_download  # << send this to delayed job
      # download.delay.assign_validity
    end
    download_array
  end
  
  def process_download
    self.assign_validity
    self.execute_download
  end
  
  def self.filter_links( unfiltered_links )
    unfiltered_links.gsub(/\s/, " ").squeeze(" ").split(" ")
  end
  
  def self.deduce_type( link ) 
    link_type = 0
    LINK_MATCHER.each do | key , value_regex | 
      if link.match value_regex 
        link_type = key 
      end
    end
    
    if link_type == 0 
      # raise the issue, send email to willy
      # maybe there is something wrong with the regex code
    end
    link_type
  end
  
  def assign_validity 
     # assume that it is always hotfile
     if self.type_id == 1 # hotfile
       check_hotfile
     else
     end
  end
  
  def check_hotfile
    digest = ""
    # getting the digest
    Net::HTTP.start("api.hotfile.com") { |http|
      base_req = "/?action=getdigest"
      resp = http.get( base_req)



      digest = resp.body
      # >>> 1293124438-1528544627-0d40f186bf6c383ba29c857c6717ff5c  << valid for 30 seconds
    }

    puts digest

    # username= "2054845"
    #  password = "jtkhgk"
    # get the usernaem from Rails.root.join("config/dutil/hotfile.yml")
    config = YAML::load(File.read(Rails.root.join('config/dutil/dutil_hotfile.yml'))) 
    username = config["hotfile"]["username"]
    password = config["hotfile"]["password"]
    
    puts "The password is #{password}"
    diggest_password =  Digest::MD5.hexdigest( password )
    puts "The password diggest si #{diggest_password}"

    final_diggested_password =   Digest::MD5.hexdigest( diggest_password + digest)
    username_and_password = "username=#{username}&passwordmd5dig=#{final_diggested_password}"
    direct_download_link = ""
    # getting the download link
    Net::HTTP.start("api.hotfile.com") { |http|
      base_req = "/?action=getdirectdownloadlink&"
      with_link = base_req + "link=#{link_loc}&"
      with_auth = with_link + username_and_password + "&digest=#{digest}"
      puts with_auth
      resp = http.get( with_auth)
      direct_download_link =  resp.body
    }

    dl_link_regex = /^http:/
    if direct_download_link.match dl_link_regex
      self.status_download = true
      self.save
    else
      # the status download will still be false by default
    end
  end
  
  def execute_download
    if download.status_download 
      # download for real
    else
      #send email to the user, telling that the link is dead
      puts "hehehe, the link is wrong / broken"
    end
  end

end
