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
    if input.include?("追加") && input[/（(.*?)）/, 1].length>0
      task_name=input[/（(.*?)）/, 1]
      group.tasks.create(name:input[/（(.*?)）/, 1])
      return task_name+"を登録しました！"
    elsif input.include?("一覧")
      return "現在の一覧です。\n"+group.tasks.map{|e|e.name}.join("\n")
    else
      return "test"
    end
  end
end
