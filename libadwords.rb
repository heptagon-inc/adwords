#!/usr/bin/env ruby
# coding: utf-8

require 'adwords_api'
require 'csv'
require 'parallel'

API_VERSION = :v201607
PAGE_SIZE = 1
THREADS = 4

module Ad
  class Concurrent
    def initialize()
      @list = []
    end

    def build_list(keyword)
      @list << keyword
    end

    def exec()
      Parallel.each(@list, in_threads: THREADS) do |keyword|
        yield keyword
      end
    end

  end

  class Analysis
    def initialize()
      adwords = AdwordsApi::Api.new
      @targeting_idea_srv = adwords.service(:TargetingIdeaService, API_VERSION)
      @nodata_keywords = []
      @csv_data = []
    end

    def get_monthly_searche_volumes(keyword_text)
      real_data = request_search_volumes(keyword_text)
      select_useful_data(real_data) do |useful_data|
        convert_csv_format(useful_data)
      end
    end

    def merge_csv_data()
      merged_csv_data = {:data => []}
      @csv_data.each do |c|
        merged_csv_data[:header] = c[:header]
        merged_csv_data[:data] << c[:data]
      end
      return merged_csv_data
    end

    def build_csv(merged_csv_header,merged_csv_data)
      csv = CSV.generate("", :headers => merged_csv_header, :write_headers => true) do |c|
        merged_csv_data.each {|d| c << d }
      end
      return csv
    end

    def write_csv(csv, filename)
      File.open(filename, 'w') {|file| file.write(csv) }
    end

    def nodata_keywords()
      return @nodata_keywords
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

    def request_search_volumes(keyword_text)
      selector = build_selector(keyword_text)
      page = @targeting_idea_srv.get(selector)
      return page[:entries] if page and page[:entries]
      return dummy_zero_data(keyword_text)
    end

    def dummy_zero_data(keyword_text)
      return [
        {
          :data => {
            "KEYWORD_TEXT" => {:value => keyword_text},
            "TARGETED_MONTHLY_SEARCHES" => {:value => []}
          }
        }
      ]
    end

    def select_useful_data(real_data)
      if real_data[0][:data]["TARGETED_MONTHLY_SEARCHES"][:value].size == 0
        @nodata_keywords << [real_data[0][:data]["KEYWORD_TEXT"][:value]]
      else
        yield real_data
      end
    end

    def convert_csv_format(useful_data)
      csv_data = Hash.new
      csv_data[:header] = ['keyword']
      target_monthly_searches = useful_data[0][:data]['TARGETED_MONTHLY_SEARCHES'][:value].reverse
      keyword_text = useful_data[0][:data]['KEYWORD_TEXT'][:value]
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
      @csv_data << csv_data
    end

  end
end
