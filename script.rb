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
    form.username = get_username
    form.password = get_password
    puts ''
  end.submit
end

def download_video(agent, link)
  post = agent.get BASE_URI + link.uri.to_s
  video_link = post.links.find { |l| l.text.end_with? '.mp4' }
  video_name = video_link.text.gsub('_', ' ')

  if File.exists? "./videos/#{video_name}"
    puts "Already Downloaded #{video_name}"
    return
  end

  puts "Downloading #{video_name.sub(/.mp4\z/, '')}..."
  agent.get(BASE_URI + video_link.uri.to_s).save("./videos/#{video_name}")
end

agent = Mechanize.new
page = agent.get(BASE_URI + '/subscriber/content')

if content = authenticate(page)
  content.links.reverse.each do |link|
    download_video agent, link if link.text =~ /file attachment/i
  end
else
  puts 'Unable to authenticate.'
end
