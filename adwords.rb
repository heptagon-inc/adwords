#!/usr/bin/env ruby
# coding: utf-8

require 'adwords_api'
require 'mysql2-cs-bind'
require 'yaml'
require 'erb'
require 'hashie'

class Ad
  def initialize
    config_file = File.expand_path "./database.yml", File.dirname(__FILE__)
    db_config = Hashie::Mash.new(YAML.load(ERB.new(IO.read(config_file)).result))
    Mysql2::Client.default_query_options.merge!(:symbolize_keys => true)
    @client = Mysql2::Client.new(db_config)
  end

  def get_keyword_ideas(keyword_text)
    page_size = 1
    api_version = :v201509

    adwords = AdwordsApi::Api.new
    targeting_idea_srv = adwords.service(:TargetingIdeaService, api_version)

    selector = {
      :idea_type => 'KEYWORD',
      :request_type => 'STATS',
      :requested_attribute_types =>
          ['KEYWORD_TEXT','TARGETED_MONTHLY_SEARCHES'],
      :search_parameters => [
        {
          :xsi_type => 'RelatedToQuerySearchParameter',
          :queries => [keyword_text]
        },
        {
          :xsi_type => 'LanguageSearchParameter',
          :languages => [{:id => 1005}]
        }
      ],
      :paging => {
        :start_index => 0,
        :number_results => page_size
      }
    }

    offset = 0
    results = []

    begin
      page = targeting_idea_srv.get(selector)
      results += page[:entries] if page and page[:entries]

      offset += page_size
      selector[:paging][:start_index] = offset
    end while offset < page_size

    results.each do |result|
      data = result[:data]
      @result = []
      @result << [
        keyword: data['KEYWORD_TEXT'][:value],
        data: data['TARGETED_MONTHLY_SEARCHES'][:value]
      ]
    end
    return @result
  end

  def insert_data(array)
    keyword = array[0][0][:keyword]
    array[0][0][:data].each do |d|
      @client.xquery("insert into adwords (keyword,year,month,count) values (?,?,?,?) on duplicate key update count = ?", keyword, d[:year].to_i, d[:month].to_i, d[:count].to_i, d[:count].to_i)
    end
  end

end

keyword_text = ARGV[0]
ad = Ad.new
res = ad.get_keyword_ideas(keyword_text)
ad.insert_data(res)
