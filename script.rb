#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

BASE_URI = 'https://elixirsips.dpdcart.com'

def get_username(prompt = 'Username: ')
  print prompt
  gets.chomp
end

def get_password(prompt = 'Password: ')
  if STDIN.respond_to?(:noecho)
    print prompt
    STDIN.noecho(&:gets).chomp
  else
    `read -s -p "#{prompt}" password; echo $password`.chomp
  end
end

def authenticate(page)
  page.form_with(name: nil) do |form|
    form.username = ENV['ELIXIRSIPS_DPDCART_USERNAME'] || get_username
    form.password = ENV['ELIXIRSIPS_DPDCART_PASSWORD'] || get_password
  end.submit
end

def download_file(agent, link)
  post = agent.get BASE_URI + link.uri.to_s
  post.search('//*[@id="blog-container"]/div/ul/li/a').each do |link|
    file_link, file_name = link['href'], link.text.strip
    if File.extname(file_name) == '.mkv'
      puts "Skipping #{file_name}..."
      next
    elsif File.exists? "./videos/#{file_name}"
      puts "Already Downloaded #{file_name}"
      next
    end

    puts "Downloading #{file_name}..."
    agent.get(BASE_URI + file_link).save("./videos/#{file_name}")
  end
end

agent = Mechanize.new
page = agent.get(BASE_URI + '/subscriber/content')

if content = authenticate(page)
  content.links.each { |link| download_file agent, link if link.text =~ /file attachment/i }
else
  puts 'Unable to authenticate.'
end
