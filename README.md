Script for downloading your Squarespace blog images in lieu of an export feature (e.g. when moving to Wordpress).

### How to Use

Run via Rake, like so (first grab the gem dependencies):

    bundle install
    rake download_images[BLOG_URL]

Where `BLOG_URL` is the absolute URL to your Squarespace site.

**Example**

    rake download_images[http://montessorium.com/blog]

**Download Location**

By default, images are downloaded into a corresponding directory for each post in `images/`.

### Windows

This will probably break if you run it on Windows due to something about open-uri and binary mode, but I'd be happy to accept a pull request.