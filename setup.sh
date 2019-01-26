#! /bin/sh

echo "Make sure you have Ruby, Ruby Gems and rbenv installed and configured."

rbenv which gem 1,2>/dev/null
if [[ $? != 0 ]]; then 
  echo "ERROR!"
  echo "Ruby version $(rbenv local) is not installed."
  echo "Please install it manually. If you have ruby-build plugin for rbenv installed, you can simply type: rbenv install"
  echo "Then you can run this script again."
  exit 1
fi

bundle version 2>/dev/null
if [[ $? != 0 ]]; then 
  echo "Installing Bundler..."
  gem install bundler || exit 2
fi

pushd src

echo "Installing gems..."
bundle install --path vendor/bundle || exit 3

echo "Installing pods"
bundle exec pod repo update
bundle exec pod install || exit 4

popd
