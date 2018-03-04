bundle exec jekyll build
cd _site
git add .
git commit -m "Site updated"
git push origin gh-pages

cd ../_posts
git add .
git commit -m "Site updated"
git push origin master
