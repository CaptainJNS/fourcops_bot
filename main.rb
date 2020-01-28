require 'telegram/bot'
require 'i18n'
require 'emoji'
require './bot_class'

I18n.load_path << Dir[File.expand_path('locales') + '/*.yml']
I18n.default_locale = :ru

BotClass.new.call
