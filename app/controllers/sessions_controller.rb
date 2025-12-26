class SessionsController < ApplicationController
  def new
    redirect_to root_path, notice: "Demo Mode - sales@thomasit.com"
  end
  
  def create
    redirect_to root_path, notice: "Demo Mode - sales@thomasit.com"
  end
end
