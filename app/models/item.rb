class Item
  include Mongoid::Document
  include Mongoid::Slug

  # Elastic Search
  include Tire::Model::Search
  include Tire::Model::Callbacks
  
  field :title
  slug :title

  paginates_per 500
  
  # Maps field values and types for search action
  mapping do
    indexes :title, :type => 'string',  :analyzer => 'snowball'
  end

  # Build json for elasticsearch index, this is the object returnd by Tire
  def to_indexed_json
    {
      title: title, 
      release_year: release_year,
      slug: self.slug
    }.to_json
  end
  
  # ElasticSearch index name
  index_name 'mongo-items'
end
