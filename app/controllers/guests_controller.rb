class GuestsController < ApplicationController
  def login
    user = User.create_guest
    sign_in user
    redirect_to root_path, notice: "ゲストとしてログインしました。"
  end
end
