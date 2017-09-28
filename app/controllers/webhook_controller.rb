class WebhookController < ApplicationController
  # // Lineからのcallbackか認証
  protect_from_forgery with: :null_session

  CHANNEL_SECRET = ENV['CHANNEL_SECRET']
  OUTBOUND_PROXY = ENV['OUTBOUND_PROXY']
  CHANNEL_ACCESS_TOKEN = ENV['CHANNEL_ACCESS_TOKEN']

  def callback
    unless is_validate_signature
      head :not_found
    end

    event = params["events"][0]
    event_type = event["type"]
    replyToken = event["replyToken"]

    id = (event["source"]["groupId"] || event["source"]["roomId"]) || event["source"]["userId"]

    case event_type
    when "message"
      @group=Group.find_or_create_by(groupId:id)
      input_text = event["message"]["text"]
      output_text = input_to_output(input_text)
    end

    client = LineClient.new(CHANNEL_ACCESS_TOKEN, OUTBOUND_PROXY)
    res = client.reply(replyToken, output_text)

    if res.status == 200
      logger.info({success: res})
    else
      logger.info({fail: res})
    end

    head :not_found
  end

  private
  # verify access from LINE
  def is_validate_signature
    signature = request.headers["X-LINE-Signature"]
    http_request_body = request.raw_post
    hash = OpenSSL::HMAC::digest(OpenSSL::Digest::SHA256.new, CHANNEL_SECRET, http_request_body)
    signature_answer = Base64.strict_encode64(hash)
    signature == signature_answer
  end

  def input_to_output(input)
    # いつかきれいにする

    if input.include?("削除")
      delete_name=input[/（(.*?)）/, 1]
      if @group.tasks.where(name:delete_name).present?
        @group.tasks.where(name:delete_name).delete_all
        return delete_name+"を削除したにゃ(ΦωΦ)もう取り消せにゃいにゃ！"
      elsif  @group.phrases.where(if:delete_name).or(@group.phrases.where(then:delete_name)).present?
        @group.phrases.where(if:delete_name).or(@group.phrases.where(then:delete_name)).delete_all
        return delete_name+"は忘れてしまったにゃ😼"
      else
        return "しまったにゃ！指定したものを見つけることができなかったにゃ！"
      end
    end

    if input.include?("追加")
      task_name=input[/（(.*?)）/, 1]
      @group.tasks.create(name:task_name)
      return task_name+"を登録したにゃ🐱"
    elsif input.include?("一覧")
      if input.include?("応答")
        return "現在の応答一覧だにゃ🐾\n"+@group.phrases.map{|e|"「"+e.if+"」といったら「"+e.then+"」"}.join("\n")
      end
      return "現在の一覧だにゃ🐾\n"+@group.tasks.map{|e|e.name}.join("\n")
    end

    if input.include?("といったら") || input.include?("と言ったら")
      if_text=input[/（(.*?)）/, 1]
      then_text=input.gsub(input[/（(.*?)）/],"")[/（(.*?)）/,1]
      if if_text.present? && then_text.present?
        @group.phrases.create(if:if_text,then:then_text)
        return "次から「"+if_text+"」って言われたら「"+then_text+"」って返すにゃん😻"
      end
    end

    if @group.phrases.where(if:input)[0].present?
      return @group.phrases.where(if:input)[0].then
    end

  end
end
