class HomeController < ApplicationController
  def index
    if user_signed_in?
      redirect_to new_praise_path
    end
  end
end
