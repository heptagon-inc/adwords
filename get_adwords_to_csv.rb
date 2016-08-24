#!/usr/bin/env ruby
# coding: utf-8

require 'adwords_api'
require 'pp'
require 'csv'

API_VERSION = :v201607
PAGE_SIZE = 1

class Ad
  def initialize()
    adwords = AdwordsApi::Api.new
    @targeting_idea_srv = adwords.service(:TargetingIdeaService, API_VERSION)
  end

  def get_monthly_searche_volumes(keyword_text)
    selector = build_selector(keyword_text)
    csv_data = request_search_volumes(selector)
    return csv_data
  end

  def merge_csv_data(csv_data)
    merged_csv_data = {:data => []}
    csv_data.each do |c|
      next if c == nil
      merged_csv_data[:header] = c[:header]
      merged_csv_data[:data] << c[:data]
    end
    return merged_csv_data
  end

  def build_csv(merged_csv_data)
    csv = CSV.generate("", :headers => merged_csv_data[:header], :write_headers => true) do |c|
      merged_csv_data[:data].each {|d| c << d }
    end
    return csv
  end

  def write_csv(csv, filename)
    File.open(filename, 'w') {|file| file.write(csv) }
  end

  private
  def build_selector(keyword_text)
    return {
      :idea_type => 'KEYWORD',
      :request_type => 'STATS',
      :requested_attribute_types =>
        ['KEYWORD_TEXT', 'SEARCH_VOLUME', 'TARGETED_MONTHLY_SEARCHES'],
      :search_parameters => [
        {
          :xsi_type => 'RelatedToQuerySearchParameter',
          :queries => [keyword_text]
        },
        {
          :xsi_type => 'LanguageSearchParameter',
          :languages => [{:id => 1005}]
        },
        {
          :xsi_type => 'NetworkSearchParameter',
          :network_setting => {
            :target_google_search => true,
            :target_search_network => false,
            :target_content_network => false,
            :target_partner_search_network => false
          }
        }
      ],
      :paging => {
        :start_index => 0,
        :number_results => PAGE_SIZE
      }
    }
  end

  def request_search_volumes(selector)
    offset = 0
    results = []
    while offset < PAGE_SIZE
      page = @targeting_idea_srv.get(selector)
      results += page[:entries] if page and page[:entries]
      offset += PAGE_SIZE
      selector[:paging][:start_index] = offset
    end
    csv_data = convert_csv_data(results)
    return csv_data
  end

  def convert_csv_data(results)
    return nil if results.size == 0
    csv_data = Hash.new
    csv_data[:header] = ['keyword']
    results.each do |result|
      target_monthly_searches = result[:data]['TARGETED_MONTHLY_SEARCHES'][:value].reverse
      keyword_text = result[:data]['KEYWORD_TEXT'][:value]
      for i in 0..11
        year = target_monthly_searches[i][:year]
        month = target_monthly_searches[i][:month]
        csv_data[:header] << "#{year}/#{month}"
      end
      csv_data[:header] << "total"
      csv_data[:data] = [keyword_text]
      total = 0
      target_monthly_searches.map do |d|
        csv_data[:data] << d[:count]
        total += d[:count]
      end
      csv_data[:data] << total
    end
    return csv_data
  end

end

#=begin
keywords = ['カヌー','キャンプ','紅葉','ウォーキング','コケ']

ad = Ad.new
csv_data = Array.new

File.open('city_list.txt') do |file|
  file.each_line do |line|
    line = line.chomp!
    keywords.each do |word|
      keyword = "#{line} #{word}"
      csv_data << ad.get_monthly_searche_volumes(keyword)
    end
  end
end

merged_csv_data = ad.merge_csv_data(csv_data)
csv = ad.build_csv(merged_csv_data)
ad.write_csv(csv, 'test.csv')
#=end

=begin
ad = Ad.new
csv_data1 = ad.get_monthly_searche_volumes('青森市\n キャンプ')
csv_data2 = ad.get_monthly_searche_volumes('青森市 キャンプ')
csv_data3 = ad.get_monthly_searche_volumes('青森市')
csv_data = [csv_data1,csv_data2,csv_data3]
merged_csv_data = ad.merge_csv_data(csv_data)
csv = ad.build_csv(merged_csv_data)
pp csv
ad.write_csv(csv, 'test.csv')
=end
