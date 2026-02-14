class PraisesController < ApplicationController
  before_action :authenticate_user!

  def index
    # Get recent logs to exclude from suggestions
    recent_logs = current_user.logs.order(created_at: :desc).limit(30).pluck(:content)
    @praises = Ai::GroupingService.suggest_praises(count: 5, exclude_praises: recent_logs, theme: params[:theme])
  rescue => e
    flash.now[:alert] = "AIからの提案を取得できませんでした: #{e.message}"
    @praises = []
  end

  def create
    if params[:praises].present?
      params[:praises].each do |praise_content|
        current_user.logs.create(content: praise_content)
      end
      flash[:notice] = "ログを保存しました！"
    end

    if params[:commit] == "次へ" || params[:next]
      redirect_to new_praise_path
    else
      redirect_to logs_path
    end
  end
end
