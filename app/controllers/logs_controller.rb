class LogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_log, only: [ :show, :edit, :update, :destroy ]

  def index
    @logs = current_user.logs.order(created_at: :desc)
    @logs = @logs.where(created_at: params[:date].to_date.all_day) if params[:date].present?
    @logs = @logs.page(params[:page]).per(20)
  end

  def show
  end

  def edit
  end

  def update
    if @log.update(log_params)
      redirect_to logs_path, notice: "ログを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @log.destroy
    redirect_to logs_url, notice: "ログを削除しました。"
  end

  def calendar
    # Simple calendar view logic
    @month = (params[:month] || Time.current).to_date
    start_date = @month.beginning_of_month.beginning_of_week(:sunday)
    end_date = @month.end_of_month.end_of_week(:sunday)
    @date_range = start_date..end_date
    @logs_by_date = current_user.logs.where(created_at: start_date..end_date).group_by { |log| log.created_at.to_date }
  end

  private

  def set_log
    @log = current_user.logs.find(params[:id])
  end

  def log_params
    params.require(:log).permit(:content)
  end
end
