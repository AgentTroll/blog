---
layout: post
title: "GitHub Pages Screwed Me Over"
date: 2017-04-08T14:16:13-07:00
---

So I restarted my blog for like the 13th time or whatever and ran into a few
minor issues...

# Octopress 3

Some good stuff. I actually kinda liked the old design, but some things about the new stock theme such as the About page in the top right corner, as well as the feature to add custom pages rather than to have just blog posts is nice (although I myself do not have any particular use for them).

The new Octopress gem is also a nice addition instead of having to use `rake` to do whatever I needed. The only thing about it is that you cannot convert posts to drafts, for it throws an odd exception along the lines of:

``` ruby
unpublish.rb:28:in `require': cannot load such file -- octopress/post (LoadError)
```

I don't know ruby so there's nothing I can do about that ¯\\\_(ツ)\_/¯

Anyways, you might see that my huge "[On Thread Safety](https://caojohnny.github.io/blog/2017/03/20/on-thread-safety.html)" post is incomplete, so if you were wondering why, blame Octopress's non-functional `unpublish` command.

Other than that, it's the same old Octopress. Good stuff.

# GitHub Pages integration

Just a minor technicality, an `index.html` file **WILL NOT** be loaded if the site is pushed to `master`. It took about 10 minutes for me realize that my blog was not loading due to it being on `master`, rather than GitHub Pages just updating the page.

Even though a GitHub Pages site works on `master`, if you want your index.html to show up on the root URL, then you must use `gh-pages`.

Had I pushed to `master`, I would need to use the URL `https://caojohnny.github.io/blog/index.html`, rather than `https://caojohnny.github.io/blog`.

# Conclusion

Anyways, its just me complaining about a minor quirk with GitHub Pages and the way it resolves URLs and some updates with Octopress.

BONUS EDIT:

After reading through my blog, I found that Octopress **DOES NOT** rebuild your pages when you do `octopress deploy`. What essentially happened was because I was using `jekyll serve` to preview the blog before publishing it, all the `{{ site.url }}` tags resolved to `localhost` instead of the intended page URL. Therefore, if you want to get all the right page variables, use:

``` sh
$ jekyll build && octopress deploy
```
