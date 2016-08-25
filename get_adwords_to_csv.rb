#!/usr/bin/env ruby
# coding: utf-8

require_relative 'lib'
require_relative 'cities'
require_relative 'keywords'
require 'pp'

def omit_city_name(city)
  return city.chop
end

ada = Ad::Analysis.new
header = ada.get_header()
@data = Array.new

@cities.each do |city|
  @keywords.each do |keyword|
    r1 = ada.get_volumes("#{city} #{keyword}")
    r2 = ada.get_volumes("#{omit_city_name(city)} #{keyword}")
    @data << ada.merge_data("#{city} #{keyword}", r1, r2)
  end
end

csv = ada.build_csv(header,@data)
ada.write_file(csv,'aomori.csv')
