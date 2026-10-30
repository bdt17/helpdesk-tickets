# The public help center (/help). Anyone can read published articles;
# staff also see drafts and are the only ones who can write or edit.
class ArticlesController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :require_staff!, except: [ :index, :show ]
  before_action :set_article, only: [ :show, :edit, :update, :destroy ]

  def index
    @query = params[:q].to_s.strip
    articles = staff? ? Article.all : Article.published
    if @query.present?
      pattern = "%#{Article.sanitize_sql_like(@query.downcase)}%"
      articles = articles.where("LOWER(title) LIKE :p OR LOWER(body) LIKE :p", p: pattern)
    end
    @articles_by_category = articles.order(:title).group_by(&:category)
  end

  def show
    raise ActionController::RoutingError, "Not Found" unless @article.published? || staff?
  end

  def new
    @article = Article.new(category: Article::CATEGORIES.first)
  end

  def create
    @article = Article.new(article_params)
    if @article.save
      redirect_to article_path(@article), notice: @article.published? ? "Article published." : "Draft saved - only staff can see it until it's published."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @article.update(article_params)
      redirect_to article_path(@article), notice: "Article updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy!
    redirect_to articles_path, notice: "Article deleted."
  end

  private

  def set_article
    @article = Article.find_by(slug: params[:id]) or raise ActionController::RoutingError, "Not Found"
  end

  def article_params
    params.require(:article).permit(:title, :slug, :summary, :body, :category, :published)
  end

  def staff?
    current_user&.agent? || current_user&.admin?
  end
  helper_method :staff?
end
