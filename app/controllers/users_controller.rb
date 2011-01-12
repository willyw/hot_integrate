class UsersController < ApplicationController
  
  def create
    @user = User.new(params[:user])
    if @user.save
      redirect_to root_url , :new_user => true
    end
  end
end
