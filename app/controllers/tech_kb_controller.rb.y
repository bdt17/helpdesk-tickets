class TechKbController < ApplicationController
  def index
    @kbs = KnowledgeBase.all
  end
  
  def search
    @kbs = KnowledgeBase.where("title ILIKE ? OR category ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%")
    render :index
  end
end

