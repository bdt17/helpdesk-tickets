require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @published = Article.create!(title: "Fix slow Wi-Fi", body: "Restart the router.", category: "Network & Wi-Fi Support", published: true)
    @draft = Article.create!(title: "Secret draft", body: "Not ready.", category: "Getting started")
  end

  test "anyone can read the help center, but only published articles" do
    get articles_url
    assert_response :success
    assert_select "a[href=?]", article_path(@published)
    assert_select "a[href=?]", article_path(@draft), count: 0

    get article_url(@published)
    assert_response :success
    assert_select "title", text: /Fix slow Wi-Fi/

    get article_url(@draft)
    assert_response :not_found
  end

  test "staff see drafts, labeled" do
    sign_in users(:agent)
    get articles_url
    assert_select "a[href=?]", article_path(@draft)
    assert_select ".badge", text: "Draft"
    get article_url(@draft)
    assert_response :success
  end

  test "search matches title and body" do
    get articles_url(q: "router")
    assert_select "a[href=?]", article_path(@published)
    get articles_url(q: "printer")
    assert_select "a[href=?]", article_path(@published), count: 0
  end

  test "staff can write and publish an article; the slug comes from the title" do
    sign_in users(:agent)
    post articles_url, params: { article: { title: "Printer Won't Print", body: "Check the paper.", category: "Computer & Hardware Support", published: "1" } }
    article = Article.find_by!(slug: "printer-won-t-print")
    assert article.published?
    assert_redirected_to article_url(article)

    patch article_url(article), params: { article: { title: "Printer won't print?" } }
    assert_equal "Printer won't print?", article.reload.title
  end

  test "a failed slug change re-renders the form pointing at the saved address" do
    sign_in users(:agent)
    patch article_url(@published), params: { article: { slug: "Bad Slug!" } }
    assert_response :unprocessable_entity
    assert_select "form[action=?]", article_path(@published)
  end

  test "clients and visitors can't write articles" do
    post articles_url, params: { article: { title: "x", body: "y", category: "Getting started" } }
    assert_redirected_to new_user_session_url

    sign_in users(:client)
    assert_no_difference "Article.count" do
      post articles_url, params: { article: { title: "x", body: "y", category: "Getting started" } }
      delete article_url(@published)
    end
  end

  test "article bodies are escaped, with paragraphs, headings and lists" do
    @published.update!(body: "Intro <script>alert(1)</script>\n\n## Steps\n\n- One\n- Two")
    get article_url(@published)
    assert_select ".article-body h2", text: "Steps"
    assert_select ".article-body li", 2
    assert_no_match "<script>alert(1)</script>", response.body
    assert_match "&lt;script&gt;", response.body
  end

  test "published articles are in the sitemap, drafts aren't" do
    get sitemap_url
    assert_includes response.body, "<loc>#{article_url(@published)}</loc>"
    assert_not_includes response.body, article_url(@draft)
  end

  test "the new-ticket page points to the help center" do
    sign_in users(:client)
    get new_ticket_url
    assert_select "a[href=?]", articles_path
  end
end
