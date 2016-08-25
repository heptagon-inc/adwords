#!/usr/bin/env ruby
# coding: utf-8

require './lib.rb'
require 'pp'

data = []
ada = Ad::Analysis.new
header = ada.get_header()
a1 = ada.get_volumes('青森 カヌー')
a2 = ada.get_volumes('青森市 カヌー')
data << ada.merge_data('青森市 カヌー',a2,a1)

b1 = ada.get_volumes('青森 キャンプ')
b2 = ada.get_volumes('青森市 キャンプ')
data << ada.merge_data('青森市 キャンプ',b2,b1)
csv = ada.build_csv(header,data)
ada.write_file(csv,'etst.csv')
