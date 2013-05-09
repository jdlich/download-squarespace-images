require './download_squarespace_images.rb'

#   
#   To download your squarespace blog images, run:
#
#     rake download_images[blog_url]
#
#   Examples:
#
#     rake download_images[https://alyssa-lichner-15e1.squarespace.com]
#     rake download_images[http://montessorium.com/blog]
#

desc 'Clear images'
task :clear do
  FileUtils.rm_r Dir["images/*"]
end

desc 'Download images'
task :download_images, :blog_url do |t, args|
  blog = SS::Blog.new(args[:blog_url])
  blog.posts.each do |post|
    post.download_images if post.images?
  end
end