class DownloadsController < ApplicationController
  
  
  def welcome
    show_two_face
    if params[:new_user]
      puts "hehehe, we are with new user \n"*200
    end
  end
  
  
  
  def show_two_face
    if current_user
      @downloads = current_user.downloads
      @new_user = User.new 
      render :file => "/downloads/show_files.html.erb"  
    else
      render :file => "/downloads/welcome.html.erb"
    end
  end

  def create
    @downloads = Download.create_batch( current_user, params[:links])
    for element in params[:links].gsub(/\s/, " ").squeeze(" ").split(" ")
      puts "the link is ----#{element}----"
    end
    redirect_to root_url
  end
  
  
end
