Script for downloading Squarespace blog images in lieu of an export feature (e.g. when moving to Wordpress).

## How to Use

Run via Rake, like so (first grab the gem dependencies):

    bundle install
    rake download_images[BLOG_URL]

Where `BLOG_URL` is the absolute URL to your Squarespace site.

**Example**

    rake download_images[http://montessorium.com/blog]

**Download Location**

By default, images are downloaded into a corresponding directory for each post in `images/`.

## How it Works

**Get Blog Index Pages**

Squarespace offers access to JSON data by appending `?format=json` (or `?format=json-pretty`) to any Squarespace URL. The JSON for a blog index page in particular gives us all 20 posts (the standard pagination limit) as an array of items.

It also gives us the total number of posts (itemCount). Total posts divided by 20 rounded up is the number of paginated index pages. Pages are accessed by appending `?page=n` to the blog URL. So, the first thing we do is construct these page URLs (which contain our posts which contain our images...) and store them in an array.

    Array(0..num_of_pages).map do |n|
      @url + "?page=#{n}&format=json"
    end

**Get Posts via JSON**

Next we replace each page URL with an array of the page's items (i.e. posts), which are also instantiated as new `SS::Post` objects. After we flatten this array of arrays of post objects, we get one big array of squarespace posts.

    page_urls.map do |url|
      json = JSON.load(open(url))
      json["items"].map { |i| SS::Post.new(i) }
    end.flatten

**Get Image URLs with Nokogiri**

Nokogiri is used to scrape the body of each post and return a collection of Squarespace image URLs via the `data-src` attribute on `<img>` tags.

    html.css('img[data-src]').map { |img| img.attr('data-src') }

**Download Images with open-uri**

Finally, the images are downloaded one at a time with `open-uri`.

    File.open(file, 'wb') do |f|
      f.write open(img.url).read
    end

## Squarespace-Hosted Images Only

This script only grabs the Squarespace images hosted on Squarespace (via the `data-src` attribute). Images that are hosted elsewhere (like Photobucket or Flickr) are skipped over. (Part of this decision has to do with open-uri having a fit over redirecting http to https and vice versa.)

## Windows

This will probably break if you run it on Windows due to something about open-uri and binary mode, but I'd be happy to accept a pull request.