#!/usr/bin/env ruby
# coding: utf-8

require 'adwords_api'
require 'csv'

API_VERSION = :v201607
PAGE_SIZE = 1
SEARCH_HEADER_WORD = '日本'

module Ad
  class Analysis
    def initialize()
      adwords = AdwordsApi::Api.new
      @targeting_idea_srv = adwords.service(:TargetingIdeaService, API_VERSION)
    end

    def get_header()
      raw_data = request_search_volumes_rawdata(SEARCH_HEADER_WORD)
      header = build_header_data(raw_data)
      return header
    end

    def get_volumes(keyword)
      return request_search_volumes(keyword)
    end

=begin
    def merge_data(keyword,main_data,sub_data)
      main_data.shift
      sub_data.shift
      e1 = main_data.to_enum
      e2 = sub_data.to_enum
      sum = []
      loop do
        sum << e1.next + e2.next
      end
      return sum.unshift(keyword)
    end
=end

    def merge_data(keyword,main_data)
      main_data.shift
      e1 = main_data.to_enum
      sum = []
      loop do
        sum << e1.next
      end
      return sum.unshift(keyword)
    end

    def build_csv(header,data)
      csv = CSV.generate("", :headers => header, :write_headers => true) do |c|
        data.each {|d| c << d }
      end
      return csv
    end

    def write_file(data,filename)
      File.open(filename, 'w') {|file| file.write(data) }
    end

    private
    def build_header_data(raw_data)
      header_data = ["keyword"]
      raw_data["TARGETED_MONTHLY_SEARCHES"][:value].reverse.each do |data|
        header_data << "#{data[:year]}/#{data[:month]}"
      end
      header_data << "total"
      return header_data
    end

    def request_search_volumes_rawdata(keyword)
      selector = build_selector(keyword)
      page = @targeting_idea_srv.get(selector)
      return page[:entries][0][:data] if page and page[:entries]
      return nil
    end

    def request_search_volumes(keyword)
      page = request_search_volumes_rawdata(keyword)
      return convert_csv_format(page) if page != nil
      return dummy_data(keyword)
    end

    def convert_csv_format(raw_data)
      csv_format_data = [raw_data["KEYWORD_TEXT"][:value]]
      total = 0
      raw_data["TARGETED_MONTHLY_SEARCHES"][:value].reverse.each do |data|
        csv_format_data << data[:count]
        total += data[:count]
      end
      csv_format_data << total
      return csv_format_data
    end

    def dummy_data(keyword)
      return [keyword,0,0,0,0,0,0,0,0,0,0,0,0,0]
    end

    def build_selector(keyword)
      return {
        :idea_type => 'KEYWORD',
        :request_type => 'STATS',
        :requested_attribute_types => ['KEYWORD_TEXT', 'TARGETED_MONTHLY_SEARCHES'],
        :search_parameters => [
          {
            :xsi_type => 'RelatedToQuerySearchParameter',
            :queries => [keyword]
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

  end
end
