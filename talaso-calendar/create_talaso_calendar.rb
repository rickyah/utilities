#!/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'ri_cal'
require 'date'
require 'time'
require 'debugger'

def get_schedule_data_from_website(website_url)
  
  schedule_data = {}
  
  doc = Nokogiri::HTML(open("#{website_url}"))
  

  # each tr element represents an hour, and contains all the activities 
  # in that hour for all days of the weeks

  doc.css("#horarios>tr").each_with_index do |hour_element, hour_index|
    
    # skip first column in the row as it only contains
    # the names of the days of the week
    next if hour_index == 0
          
     hour_element.css('>td').each_with_index do |day_activities, day_schedule_index|
      
      # skip first column in the inner table row as it only contains
      # the current hour
      next if day_schedule_index == 0
      
      # get data
      day_activities.css('table').each do |activity_data|
          
          activity_data.css('tr td').each do |schedule_element_data|
                    
          schedule_data[day_schedule_index] = [] if schedule_data[day_schedule_index].nil?
          
            schedule_data[day_schedule_index] << {
              :start        => schedule_element_data.xpath('.//text()').first.text.split('-')[0].strip,
              :end          => schedule_element_data.xpath('.//text()').first.text.split('-')[1].strip,
              :name         => schedule_element_data.css('a').text.strip,
              :description  => schedule_element_data.css('a').attribute('title').text.strip
            }

          end

      end
    end
  end
  
  schedule_data
end

def generate_icalendar_data schedule_data
  time_format = "%Y/%m/%d %H:%M"

  cal = RiCal.Calendar do
    7.times do |idx|
      day = Time.new(Time.now.year, Time.now.month, idx+1)
      wday = day.wday
      wday = 0 if wday == 8
    
      unless schedule_data[wday].nil?
      
        schedule_data[wday].each do |activity_data|
          event do
            summary     activity_data[:name]
            description activity_data[:description]
            dtstart     Time.parse("#{day.strftime('%Y/%m/%d')} #{activity_data[:start]}" , time_format).with_floating_timezone
            dtend       Time.parse("#{day.strftime('%Y/%m/%d')} #{activity_data[:end]}" , time_format).with_floating_timezone
            rrule       :freq => 'weekly', :until => Date.new(day.year, day.month, -1).to_time.with_floating_timezone
           end
        end
      end
    end
  end
  
end

def write_to_file filename, str_data
  File.open(filename, "w") do |file|
    file.write(str_data)
  end
end

filename = ARGV[0] || "talaso.ics"

write_to_file filename, generate_icalendar_data(get_schedule_data_from_website('http://talasoponiente.com/html/main.asp?id_mapa=0001'))

