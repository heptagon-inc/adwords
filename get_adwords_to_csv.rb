#!/usr/bin/env ruby
# coding: utf-8

require './libadwords.rb'

keywords = ['カヌー','キャンプ','紅葉','ウォーキング','コケ']

adc = Ad::Concurrent.new
ada = Ad::Analysis.new

File.open('city_list.txt') do |file|
  file.each_line do |line|
    line.chomp!
    keywords.each do |word|
      keyword = "#{line} #{word}"
      adc.build_list(keyword)
    end
  end
end

adc.exec do |keyword|
  ada.get_monthly_searche_volumes(keyword)
end

merged_csv_data = ada.merge_csv_data()
csv = ada.build_csv(merged_csv_data[:header],merged_csv_data[:data])
ada.write_csv(csv, 'aomori.csv')

nodata_csv = ada.build_csv(['nodata_keyword'],ada.nodata_keywords())
ada.write_csv(nodata_csv, 'aomori_nodata.csv')
