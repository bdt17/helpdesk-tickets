class KnowledgeBasesController < ApplicationController
  def index
    @articles = KnowledgeBase.all.order(:title)
  end
end
