require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone_number)
  phone_number.gsub(/[^0-9]/, "")

  if phone_number.length == 10
    phone_number
  elsif phone_number.length == 11 && phone_number[0] == "1"
    phone_number[1..10]
  else
    "Bad Number!"
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def time_targeting(reghours)  
  reghours = reghours.split(" ")[1].split(":")[0].to_i

  if reghours > 12
    reghours -= 12
    reghours.to_s + "PM"
  else
    reghours.to_s + "AM"
  end
end

def most_common_reg_day
  contents = CSV.open("../event_attendees.csv", headers: true, header_converters: :symbol)
  reg_day_array = []
  contents.each do |row|
    reg_date = row[:regdate]
    reg_day = Time.strptime(reg_date, '%M/%d/%y %k:%M').strftime('%A')
    reg_day_array.push(reg_day)
  end
  most_common_day = reg_day_array.reduce(Hash.new(0)) do |hash, day|
    hash[day] += 1
    hash
  end
  most_common_day.max_by { |_k, v| v }[0]
end

puts 'EventManager initialized.'

contents = CSV.open(
  '../event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('../form_letter.erb')
erb_template = ERB.new template_letter
hours_hash = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  hours_hash[:"#{time_targeting(row[:regdate])}"] += 1

  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)
end

puts "The most registered hour was:"
puts hours_hash.max_by { |k, v| v }

puts "\nThe total list of registered hours is:"
puts hours_hash.each { |k, v| "#{k}: #{v}" }

puts "\nThe most common registration day is: #{most_common_reg_day}"

# used somebody elses code for registration day !! need to fix up for myself and add comments into code !! going to bed