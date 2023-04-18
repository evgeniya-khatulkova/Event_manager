require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone(phone)
  count = phone.to_s.scan(/\d/).size
  if count == 11 && phone[0] == '1'
    phone[1..11]
  elsif count > 10
    'Number is invalid'
  elsif count < 10
    'Number is invalid'
  else
    phone
  end
end

def find_perfect_time(time_array)
  time_count = Hash.new(0)
  time_array.each { |time| time_count[time] += 1 }
  amount = time_count.max_by { |__, value| value }
  result = time_count.collect { |key, value| key if value == amount[1] }.compact
  p result
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
    begin
      civic_info.representative_info_by_address(
        address: zipcode,
        levels: 'country',
        roles: ['legislatorUpperBody', 'legislatorLowerBody']).officials
    rescue
      'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename.to_s, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  '../event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('../form_letter.erb')
erb_template = ERB.new template_letter

time_array = []

contents.each do |row|
  id = row[0]

  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  phone = clean_phone(row[:homephone])

  legislators_name = legislators_by_zipcode(zipcode)

  date = row[:regdate].split

  day = date[0]

  time = Time.parse(date[1]).hour

  time_array << time

  # form_letter = erb_template.result(binding)

  # save_thank_you_letter(id, form_letter)
end

find_perfect_time(time_array)
