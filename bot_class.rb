class BotClass
  def call
    Telegram::Bot::Client.run(ENV['bot-token']) do |bot|
      bot.listen do |message|
        case message.text
        when '/start_game' then start_game(bot, message)
        when '/stop_game' then end_game(bot, message)
        when '/go' then go(bot, message)
        when '/ru' then I18n.locale = :ru
        when '/en' then I18n.locale = :en
        when '/rules' then show_rules(bot, message)
        when '/help' then show_help(bot, message)
        end
      end
    end
  end

  private

  THUMB_UP = Emoji.find_by_alias('thumbsup').raw
  THUMB_DOWN = Emoji.find_by_alias('-1').raw
  HOMICIDE = Emoji.find_by_alias('gun').raw

  def start_game(bot, message)
    bot.api.send_message(chat_id: message.chat.id, text: I18n.t(:start_game))
    go(bot, message)
  end

  def go(bot, message)
    input_players(bot, message) while @players&.size != 5
    create_roles if @player_roles.nil?
    who_walks(bot, message)
    bot.api.send_message(chat_id: message.chat.id, text: I18n.t(:role_is, player: @player, role: I18n.t("roles.#{@player_roles[@player]}")))
    where_walks(bot, message)
    answer(bot, message)
    final(bot, message)
  end

  def end_game(bot, message)
    @players = nil
    @player_roles = nil
    bot.api.send_message(chat_id: message.chat.id, text: I18n.t(:stop_game))
  end

  def input_players(bot, message)
    bot.api.send_message(chat_id: message.chat.id, text: I18n.t(:input_players))
    bot.listen { |m| @players = m.text.split(/[\s,]+/).map(&:capitalize); break }
  end

  def create_roles
    @player_roles = Hash[@players.shuffle.zip I18n.t(:roles).keys.shuffle]
  end

  def who_walks(bot, message)
    players =
      Telegram::Bot::Types::ReplyKeyboardMarkup
      .new(keyboard: [@players[0...3], @players[3...5]], one_time_keyboard: true)
    @player = ''
    until @players.include?(@player) do
      bot.api.send_message(chat_id: message.chat.id, text: I18n.t(:who_walks), reply_markup: players)
      bot.listen { |m| @player = m.text; break }
    end
  end

  def where_walks(bot, message)
    players =
      Telegram::Bot::Types::ReplyKeyboardMarkup
      .new(keyboard: [@players[0...3], @players[3...5]], one_time_keyboard: true)
    @victim = ''
    until @players.include?(@victim) do
      bot.api.send_message(chat_id: message.chat.id, text: I18n.t(:where_walks, player: @player), reply_markup: players)
      bot.listen { |m| @victim = m.text; break }
    end
  end

  def answer(bot, message)
    case @player_roles[@player]
    when :mafia then bot.api.send_message(chat_id: message.chat.id, text: I18n.t(:killed) + HOMICIDE)
    when :only_yes then bot.api.send_message(chat_id: message.chat.id, text: I18n.t(:good) + THUMB_UP)
    when :only_no then bot.api.send_message(chat_id: message.chat.id, text: I18n.t(:bad) + THUMB_DOWN)
    when :only_false
      if @player_roles[@victim] == :mafia then bot.api.send_message(chat_id: message.chat.id, text: I18n.t(:good) + THUMB_UP)
      else bot.api.send_message(chat_id: message.chat.id, text: I18n.t(:bad) + THUMB_DOWN)
      end
    when :only_true
      if @player_roles[@victim] == :mafia then bot.api.send_message(chat_id: message.chat.id, text: I18n.t(:bad) + THUMB_DOWN)
      else bot.api.send_message(chat_id: message.chat.id, text: I18n.t(:good) + THUMB_UP)
      end
    end
  end

  def final(bot, message)
    variants =
      Telegram::Bot::Types::ReplyKeyboardMarkup
      .new(keyboard: %w[/go /stop_game], one_time_keyboard: true)
    bot.api.send_message(chat_id: message.chat.id, text: I18n.t(:final), reply_markup: variants)
  end

  def show_rules(bot, message)
    rules = File.read('rules.txt')
    bot.api.send_message(chat_id: message.chat.id, text: rules)
  end

  def show_help(bot, message)
    bot.api.send_message(chat_id: message.chat.id, text: I18n.t(:help))
  end
end
