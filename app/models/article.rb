# Public help-center articles at /help (see ArticlesController). Staff
# write them from the site; only published ones are visible to everyone
# else and listed in the sitemap. Each one is another page search engines
# can index, and the new-ticket form points clients here first, so common
# questions get answered without a ticket.
#
# body is plain text with a tiny bit of structure (see
# ArticlesHelper#article_body): blank lines split paragraphs, "## " starts
# a heading and "- " lines become a bulleted list. No HTML is ever
# rendered from it.
class Article < ApplicationRecord
  CATEGORIES = [ "Getting started", *ServicePage::ALL.map(&:name) ].freeze

  validates :title, presence: true, length: { maximum: 150 }
  validates :body, presence: true, length: { maximum: 50_000 }
  validates :summary, length: { maximum: 300 }
  validates :category, inclusion: { in: CATEGORIES }
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, message: "can only use lowercase letters, numbers and dashes" }

  before_validation :default_slug

  scope :published, -> { where(published: true) }

  # The saved slug, so a form re-rendered after a failed slug change still
  # submits to the article's current address.
  def to_param
    slug_in_database || slug
  end

  # Short text for meta descriptions and listings.
  def blurb
    summary.presence || body.to_s.squish.truncate(160)
  end

  private

  def default_slug
    self.slug = title.to_s.parameterize if slug.blank?
  end
end
