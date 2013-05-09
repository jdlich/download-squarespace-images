#! /usr/bin/env ruby -w

require 'yaml'
require 'json'
require 'fileutils'
require 'date'
require 'open-uri'
require 'nokogiri'

#
#   When the URL to an image is a directory, we need to
#   determine the filetype based on its contents in order
#   to append the right extension to the filename. This
#   gem gets the job done.
#
require "sixarm_ruby_magic_number_type"

#
#   open-uri will return a StringIO object instead of
#   a TempFile for files less than 10kb, (which magic_number
#   trips on) so to force open-uri to always return a
#   TempFile we need to remove this threshold by resetting
#   the StringMax constant to 0
#
#   Stackoverflow: http://bit.ly/tHKKb
#
OpenURI::Buffer.send :remove_const, 'StringMax' if OpenURI::Buffer.const_defined?('StringMax')
OpenURI::Buffer.const_set 'StringMax', 0

module SS
  
  class Blog
  
    def initialize(url)
      @url  = url.gsub(/\/$/,'') # drop trailing slash if there is one
      json?(@url)
      valid?(@json)
    end
    
    def posts
      page_urls.map do |url|
        json = JSON.load(open(url))
        json["items"].map { |i| SS::Post.new(i) }
      end.flatten
    end
  
    def page_urls
      Array(0..num_of_pages).map do |n|
        @url + "?page=#{n}&format=json"
      end
    end
  
    def num_of_pages
      items = @json['collection']['itemCount']
      (items/20.0).ceil
    end
    
    def json?(url)
      print "Checking for json... "
      begin
        @json = JSON.load(open(@url + '?format=json'))
      rescue StandardError
        puts "\e[31m#fail\e[0m"
        puts 'Try a Squarespace site.'
        exit
      else
        puts "\e[32mOK\e[0m"
      end
    end
    
    def valid?(json)
      print "Checking for blog... "
      if json['collection']['typeName'] == 'page'
        puts "\e[31m#fail\e[0m"
        puts 'Try your Squarespace blog.'
        exit
      else
        puts "\e[32mOK\e[0m"
      end
    end
  end

  class Post
      
    def initialize(post)
      @post = post
    end
    
    def download_images(location=nil)
      default_location = 'images/' + date + '-' + slug
      location ||= default_location
      mkdir(location)
      images.each do |img|
        file = location + '/' + img.filename
        File.open(file, 'wb') do |f|
          f.write open(img.url).read
          puts location + '/' + "\e[32m#{img.filename}\e[0m"
        end
      end
    end
    
    def images?
      images.length > 0
    end
  
    def images
      embedded_images.push(asset_image).map do |image_url|
        SS::Image.new(image_url) if SS::Image.valid?(image_url)
      end.compact
    end
    
    def date
      created_at = @post['addedOn']
      created_at = created_at.to_s.sub(/\d\d\d$/,'').to_i # drop last 3 numbers
      Time.at(created_at).strftime('%Y-%m-%d')
    end
  
    def asset_image
      @post['assetUrl']
    end
  
    def embedded_images
      html.css('img[data-src]').map { |img| img.attr('data-src') }
    end
  
    def html
      html = @post['body']
      Nokogiri::HTML(html)
    end
  
    def slug
      @post['urlId'].split('/').last.gsub(/\..+$/,'') # remove .html in some cases
    end
    
    private
    
    def mkdir(dir)
      FileUtils.mkdir(dir) unless File.exists?(dir)
    end    
  end

  class Image
  
    attr_reader :url
  
    def initialize(image_url)
      @url = image_url
    end
  
    def filename
      name = @url.split('/').last
      name.match(/\.\w+$/) ? name : name + '.' + ext
    end
  
    def ext
      File.magic_number_type(open(@url)).to_s
    end
    
    def self.valid?(image_url)
      begin
        open(image_url)
      rescue RuntimeError
        false
      rescue OpenURI::HTTPError
        false
      else
        true
      end
    end
  end
end
