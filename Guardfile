# More info at https://github.com/guard/guard#readme

guard 'bundler' do
  watch('Gemfile')
end

guard 'shell' do
  watch(%r{^public/javascripts/(.+\.coffee)$}) { `coffee -c public/javascripts/$1` }
end

guard 'livereload' do
  watch(%r{.+\.js})
  watch(%r{.+\.erb})
end

guard 'jasmine-headless-webkit', :jasmine_config => 'public/javascripts/spec/jasmine.yml' do
  watch(%r{^public/javascripts/(.*)\.coffee}) { |m| "public/javascripts/spec/#{m[1]}_spec" }
end

