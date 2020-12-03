class LinebotController < ApplicationController
    require 'line/bot'
    require "selenium-webdriver"
    # callbackアクションのCSRFトークン認証を無効
    protect_from_forgery :except => [:callback]    

      # LINE Developers登録完了後に作成される環境変数の認証
    def client
      
      @client ||= Line::Bot::Client.new { |config|
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
      }
    end
  
    def callback
      body = request.body.read

      signature = request.env['HTTP_X_LINE_SIGNATURE']

      unless client.validate_signature(body, signature)
        error 400 do 'Bad Request' end
      end
      events = client.parse_events_from(body)
      
      message = "test"
      message = amazon_login(message)


      events.each do |event|
        case event
        when Line::Bot::Event::Message
          case event.type
          when Line::Bot::Event::MessageType::Text
            message = {
              type: 'text',
              text: message
            }
          end
        end
        
        client.reply_message(event['replyToken'], message)
      end
      head :ok

      

    end

    def amazon_login(message)
      #Chrome用のドライバ
      driver = Selenium::WebDriver.for :chrome

      #amazonにアクセスする
      driver.get "https://www.amazon.co.jp/ap/signin?openid.pape.max_auth_age=0&openid.return_to=https%3A%2F%2Fwww.amazon.co.jp%2F%3Fref_%3Dnav_signin&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.assoc_handle=jpflex&openid.mode=checkid_setup&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0&"

      # メールアドレス
      element = driver.find_element(:name, 'email')
      element.send_keys "pirorin2810@gmail.coma"
      element.submit
      
      error = driver.find_element(:class, 'a-alert-content')

      if error.text == "このEメールアドレスを持つアカウントが見つかりません" then

        message = message + "メルアド間違えてる"
        driver.quit
        return message
      end 

      #パスワード
      element2 = driver.find_element(:name, 'password')
      element2.send_keys "自分のパスワード"

      #実行キーの押下
      element2.submit

      sleep(3)
      driver.quit
    end

  end