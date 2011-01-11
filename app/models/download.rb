# for hotfile
require 'httparty'
require 'pp'
require 'digest/md5'
require 'fileutils'

require 'net/http'
require 'active_support'
# end


# interface == check_#{hotfile, rapidserve, fileserve}

class Download < ActiveRecord::Base
  belongs_to :user
  
  #include Dutil  << if this in-class implementation is successful, implement it as Dutil
  
  LINK_MATCHER = {1 => /^(http:\/\/)?hotfile.com/, 
                  2 => /^(http:\/\/)?fileserve.com/,
                 3 => /^(http:\/\/)?fileserve.com/}
                 
  DOWNLOADER_MATCHER = {
    1 => "hotfile",
    2 => "fileserve",
    3 => "rapidshare"
  }
  
  def self.create_batch( current_user, unfiltered_links )
    download_array = []
    for link in Download.filter_links( unfiltered_links ) 
      # link_type = Download.deduce_type( link )
      link_type_id = Download.deduce_type( link )
      download = current_user.downloads.create( :link => link, :type_id => link_type_id )
      download_array << download
    
      # download.assign_validity  # << delayed job, with the highest priority
      # download.delay.process_download  << we set handle async
      download.process_download 
      
      
      # download.execute_download  # << send this to delayed job
      # download.delay.assign_validity
    end
    download_array
  end
  
  def process_download
    self.assign_validity
    self.execute_download
  end
  handle_asynchronously :process_download
  
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
     elsif self.type_id == 2
       check_fileserve
     end
     
     # see all those checking.. we can replace it with meta-programming
     
     # if the link matches none of the registered type_id, its status 
     # download is false.. skipped. Admin will be notified
  end
  
  
  
  def execute_download
    if self.status_download  and self.type_id != 0
      # download for real
      if self.type_id == 1 # hotfile
         download_hotfile
       elsif self.type_id == 2 
         download_fileserve
       end
    else
      #send email to the user, telling that the link is dead
      puts "hehehe, the link is wrong / broken"
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

    # username= "****"
    #  password = "****"
    # get the usernaem from Rails.root.join("config/dutil/hotfile.yml")
    config = YAML::load(File.read(Rails.root.join('config/dutil/dutil.yml'))) 
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
      with_link = base_req + "link=#{self.link}&"
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
  
  
  def download_hotfile
    digest = ""
    # getting the digest
    Net::HTTP.start("api.hotfile.com") { |http|
      base_req = "/?action=getdigest"
      resp = http.get( base_req)



      digest = resp.body
    }

    puts digest

    # username= "***"
    # password = "****"
    config = YAML::load(File.read(Rails.root.join('config/dutil/dutil.yml'))) 
    username = config["hotfile"]["username"]
    password = config["hotfile"]["password"]

    puts "The password is #{password}"
    diggest_password =  Digest::MD5.hexdigest( password )
    puts "The password diggest si #{diggest_password}"

    final_diggested_password =   Digest::MD5.hexdigest( diggest_password + digest)
    puts "The final digested password is #{final_diggested_password}"

    # $digest = getdigest(); // your function that does api call for the digest
    # $passwordmd5dig = md5(md5('password').$diggest);
    # username=username&passwordmd5dig=$passwordmd5dig

    username_and_password = "username=#{username}&passwordmd5dig=#{final_diggested_password}"
    # link_loc = "http://hotfile.com/dl/68975159/f4412c4/pragmatic.practical.programming.apr.2009.rar.html"

    # link_loc = http://hotfile.com/dl/88506414/3af7c03/PIC186.tmp.jpg.html
    direct_download_link = ""
    # getting the download link
    Net::HTTP.start("api.hotfile.com") { |http|
      base_req = "/?action=getdirectdownloadlink&"
      with_link = base_req + "link=#{self.link}&"
      with_auth = with_link + username_and_password + "&digest=#{digest}"
      puts with_auth
      resp = http.get( with_auth)



      direct_download_link =  resp.body
    }
    puts "The direct download link is #{direct_download_link}"

    regex = /http:\/\/(.*hotfile.com)(.*)/
    uri = ""
    path = ""
    if( direct_download_link.match regex ) 
      uri = $1
      path = $2
    else
      puts "Shite, doesn't match"
    end

    puts "The uri is " + uri
    puts "The path is " + path
    filename = "random_filename"
    filename_regex  = /.*\/(.*)$/
    if( path.match filename_regex ) 
      filename = $1
    end

    Net::HTTP.start(uri) { |http|
      resp = http.get(path)
      open("#{filename}", "wb") { |file|
        file.write(resp.body)
       }
    }
    puts "The filename is #{filename}"
    source = Dir.pwd + "/#{filename}"
    destination = "/home/app/Dropbox"
    FileUtils.move source, ( destination + "/" + download.user.email )
    
    
    self.status_download = true
    self.save
    puts "Done with moving the file to the source"
    puts "checking for the upload"
    # wait_for_upload
    puts "current TIme is #{Time.now}"
    self.delay(:run_at =>30.seconds.from_now ).wait_for_upload 

  end
  
  def wait_for_upload
    puts "Time in wait_for_upload is #{Time.now}"
    puts "wait_for_upload ahahaha\n"*20
    # if self.status_upload
    #   return 
    # else
    #   puts "The time now is #{Time.now}"
    #   self.delay.wait_for_upload  :run_at => 30.seconds.from_now 
    #   puts "The after delay time is #{Time.now}"
    # end
  end
  
  # def wait_for_upload
  #    if self.status_upload
  #      return 
  #    end
  #    
  #    puts "Gonna enter the loop of waiting"
  #    puts "But, let's sleep for 1 minute"
  #    puts "Time now is #{Time.now}"
  #    sleep 1.minutes.to_i
  #    puts "Time after sleeping is #{Time.now}"
  #    time_to_wait = -1
  #    counter = 0 
  #    while time_to_wait != 0 do 
  #      counter = counter + 1
  #      puts "In the loop number #{counter}"
  #      upload_status =  `~/bin/dropbox.py status`
  #      puts "The upload_status is #{upload_status}"
  #      if upload_status != "Idle\n"
  #        inner_regex = /\((.*)\)/
  #        if  upload_status.match inner_regex
  #          upload_data = $1.split(" ")
  #          speed = upload_data[0]
  #          numerator = upload_data[2]
  #          time_unit = upload_data[3]
  #          time_to_wait = ""
  #          puts "The speed is #{speed}, the numerator is #{numerator}, the unit is #{time_unit}"
  #          if time_unit == "min"
  #            time_to_wait =  numerator.to_i.minutes.to_i
  #          elsif time_unit == "sec"
  #            time_to_wait =  numerator.to_i.seconds.to_i
  #          else
  #            time_to_wait = numerator.to_i.hours.to_i
  #          end
  #          puts "next call is #{numerator} #{time_unit} from now\n"*10
  #        else
  #          time_to_wait = 1.minutes.to_i
  #        end
  #        puts "Gonna sleep for #{time_to_wait} seconds"
  #        # sleep time_to_wait
  #        # sleep == make the whole system sleep as unity
  #        # it means, the uploading sleep as well
  #      else
  #        self.status_upload = true
  #        self.save
  #        time_to_wait = 0
  #      end
  #    end
  #    
  #  end
  #    
  def is_upload_done?
    if self.status_upload 
      break
    else
      puts "In the is_upload_done?\n"*20
      upload_status =  `~/bin/dropbox.py status`
      #  parse this 
      # Uploading 1 file (2014 KB/sec, 26 sec left)\n
      # sec_regex = /\( ( *\d+ (sec|min) left)\) /
      #     test_regex = /(sec|min)/  # working

      if upload_status != "Idle\n"
        # string_result = "ploading 1 file (2014 KB/sec, 26 sec left)\n"
        inner_regex = /\((.*)\)/
        # it will give "2014 KB/sec, 26 sec left"
        if  upload_status.match inner_regex
          upload_data = $1.split(" ")
          speed = upload_data[0]
          numerator = upload_data[2]
          time_unit = upload_data[3]
          time_to_send = ""
          # puts "The speed is #{speed}, the numerator is #{numerator}, the unit is #{time_unit}"
          if time_unit == "min"
            time_to_send =  numerator.to_i.minutes.to_i
          elsif time_unit == "sec"
            time_to_send =  numerator.to_i.seconds.to_i
          else
            time_to_send = numerator.to_i.hours.to_i
          end

          puts "next call is #{numerator} #{time_unit} from now\n"*10
          
        else
          self.delay.is_upload_done? :run_at =>  1.minutes.from_now 
        end
        # Uploading 1 file (706.4 KB/sec, 3 min left)\n
        # "Uploading 1 file...\nDownloading file list...\n"
        # "Idle\n"
        # if not "Idle\n", check 5 mins later, or wait for callback
      else
        self.status_upload = true
        self.save
      end
    end
      
    
    
    
  end

end
