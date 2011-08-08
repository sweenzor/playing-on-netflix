namespace :netflix do
  task :all => :environment do
    consumer_key = "cfpcrjefjzfkfnj78uqwyu9d"
    secret = "QDuAqHfPtj"
    client = OAuth::Consumer.new(consumer_key, secret, :site => 'http://api.netflix.com')

    response = client.request(:get, "/catalog/titles/index")
    objects = Nokogiri::XML(response.body)

    objects.xpath('//catalog_title_index/title_index_item').each do |item|
      title = Hash.from_xml(item.to_s)

      Item.create({
        title: title[:title_index_item][:title],
        release_year: title[:title_index_item][:release_year],
        delivery_formats: title[:title_index_item][:delivery_formats],
        links: title[:title_index_item][:link],
        category: title[:title_index_item][:category],
        uri: title[:title_index_item][:id]
      })
    end
  end
end