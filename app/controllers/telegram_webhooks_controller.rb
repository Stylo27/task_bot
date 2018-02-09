class TelegramWebhooksController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext
  context_to_action!

  def start(*)
    @user = User.create(user_params)
    if @user.save
      respond_with :message, text: t('.content')
    end
  end

  def help(*)
    respond_with :message, text: t('.content')
  end

  def list
    @tasks = Task.all
    if @tasks.any?
      response_text = "Активные задачи:\n"
      @tasks.find_each.with_index do |task, index|
        response_text += "\n#{index+1}) #{task.description}\n"
      end
      respond_with :message, text: response_text, reply_markup: {
        inline_keyboard: [
          [{text: 'Delete', callback_data: 'choose'}]
        ]
      }
    else
      response_with :message, text: 'У вас нет задач'
    end
  end

  def add(*args)
    if args.any?
      @task = Task.create(description: args.join(" "), user_id: user_params['id'])
      if @task.save
        respond_with :message, text: 'Задача записана'
      else
        respond_with :message, text: 'Задача не может быть записана'
      end
    else
      respond_with :message, text: 'Напишите вашу задачу'
      save_context :add
    end
  end


  def memo(*args)
    if args.any?
      session[:memo] = args.join(' ')
      respond_with :message, text: t('.notice')
    else
      respond_with :message, text: t('.prompt')
      save_context :memo
    end
  end

  def remind_me
    to_remind = session.delete(:memo)
    reply = to_remind || t('.nothing')
    respond_with :message, text: reply
  end

  def keyboard(value = nil, *)
    if value
      respond_with :message, text: t('.selected', value: value)
    else
      save_context :keyboard
      respond_with :message, text: t('.prompt'), reply_markup: {
        keyboard: [t('.buttons')],
        resize_keyboard: true,
        one_time_keyboard: true,
        selective: true,
      }
    end
  end

  # def inline_keyboard
  #   respond_with :message, text: t('.prompt'), reply_markup: {
  #     inline_keyboard: [
  #       [
  #         {text: t('.alert'), callback_data: 'alert'},
  #         {text: t('.no_alert'), callback_data: 'no_alert'},
  #       ],
  #       [{text: t('.repo'), url: 'https://github.com/telegram-bot-rb/telegram-bot'}],
  #     ],
  #   }
  # end

  def callback_query(data)
    if data == 'choose'
      return
    else
      binding.pry
      Task.all[data].delete
    end
  end

  def message(message)
    respond_with :message, text: t('.content', text: message['text'])
  end

  def inline_query(query, _offset)
    query = query.first(10) # it's just an example, don't use large queries.
    t_description = t('.description')
    t_content = t('.content')
    results = Array.new(5) do |i|
      {
        type: :article,
        title: "#{query}-#{i}",
        id: "#{query}-#{i}",
        description: "#{t_description} #{i}",
        input_message_content: {
          message_text: "#{t_content} #{i}",
        },
      }
    end
    answer_inline_query results
  end

  # As there is no chat id in such requests, we can not respond instantly.
  # So we just save the result_id, and it's available then with `/last_chosen_inline_result`.
  def chosen_inline_result(result_id, _query)
    session[:last_chosen_inline_result] = result_id
  end

  def last_chosen_inline_result
    result_id = session[:last_chosen_inline_result]
    if result_id
      respond_with :message, text: t('.selected', result_id: result_id)
    else
      respond_with :message, text: t('.prompt')
    end
  end

  def action_missing(action, *_args)
    if command?
      respond_with :message, text: t('telegram_webhooks.action_missing.command', command: action)
    else
      respond_with :message, text: t('telegram_webhooks.action_missing.feature', action: action)
    end
  end

  private

  def user_params
    self.from.except!("is_bot", "language_code")
  end

end
