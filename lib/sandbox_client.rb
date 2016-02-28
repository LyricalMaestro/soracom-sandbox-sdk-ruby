require 'net/http'
require 'uri'
require 'json'

class LoginError < StandardError; end

class SandboxClient

  def initialize(sandbox_email, sandbox_password, auth_key_id, auth_key)
    auth_info_json = login_sandbox(sandbox_email, sandbox_password, auth_key_id, auth_key)
    if(auth_info_json == nil)
      raise LoginError, "ログイン失敗"
    end
    auth_info = JSON.parse(auth_info_json)
    @sandbox_email = sandbox_email
    @sandbox_password = sandbox_password
    @api_key = auth_info["apiKey"]
    @token = auth_info["token"]
  end

  # 架空の課金情報を登録する。
  def regist_dummy_payment
    if(!regist_payment())
      return false
    end

    auth_info_json = auth(@sandbox_email, @sandbox_password)
    if(auth_info_json == nil)
      raise LoginError, "ログイン失敗"
    end
    auth_info = JSON.parse(auth_info_json)
    @token = auth_info["token"]
    return true
  end

  # 架空のsubscriberを生成します。
  def create_new_subscribers
    subscriber_json = create_subscriber()
    if(subscriber_json == nil)
      return nil
    end

    subscriber = JSON.parse(subscriber_json)
    registet_subscriber_json = regist_subscriber(subscriber)
    if(registet_subscriber_json == nil)
      return nil
    end
    return JSON.parse(registet_subscriber_json)
  end

  # 条件にマッチするSubscriberのリストを返す。
  def subscribers
    response = https_get_with_auth("https://api-sandbox.soracom.io/v1/subscribers");
    case response
    when Net::HTTPBadRequest
      p response.read_body()
      return;
    end
    return JSON.parse(response.body)
  end

  private

  # JSONをPOST送信します。
  def https_post(uri_str, json_payload = nil)
    uri = URI.parse(uri_str)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true # HTTPSでよろしく
    req = Net::HTTP::Post.new(uri.request_uri)
    req["Content-Type"] = "application/json" # httpリクエストヘッダの追加
    if(json_payload != nil)
      req.body = json_payload # リクエストボデーにJSONをセット
    end
    response = https.request(req)
    return response
  end

  def https_post_with_auth(uri_str, json_payload = nil)
    uri = URI.parse(uri_str)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true # HTTPSでよろしく
    req = Net::HTTP::Post.new(uri.request_uri)
    req["Content-Type"] = "application/json" # httpリクエストヘッダの追加
    req["X-Soracom-API-Key"] = @api_key
    req["X-Soracom-Token"] = @token
    if(json_payload != nil)
      req.body = json_payload # リクエストボデーにJSONをセット
    end
    response = https.request(req)
    return response
  end

  def https_get_with_auth(uri_str)
    uri = URI.parse(uri_str)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true # HTTPSでよろしく
    req = Net::HTTP::Get.new(uri.request_uri)
    req["X-Soracom-API-Key"] = @api_key
    req["X-Soracom-Token"] = @token
    response = https.request(req)
    return response
  end

  # SANDBOX環境へのサインアップを行います
  def signup_sandbox(sandbox_emal, sandbox_password)
    payload = '{ "email":"%s", "password": "%s" }' % [sandbox_emal, sandbox_password]
    response = https_post("https://api-sandbox.soracom.io/v1/operators", payload)
    case response
    when Net::HTTPBadRequest
      p response.read_body()
      return false
    end
    return true
  end

  # サインアップトークンを取得
  def get_signup_token(sandbox_emal, auth_key_id, auth_key)
    uri_str = "https://api-sandbox.soracom.io/v1/sandbox/operators/token/%s" % sandbox_emal
    payload = '{ "authKeyId":"%s", "authKey": "%s" }' % [auth_key_id, auth_key]
    response = https_post(uri_str, payload)
    case response
    when Net::HTTPBadRequest
      p response.read_body()
      return;
    end
    return response.body
  end

  # サインアップ
  def signup(token)
    response = https_post("https://api-sandbox.soracom.io/v1/operators/verify", token)
    case response
    when Net::HTTPBadRequest, Net::HTTPNotFound
      p response.read_body()
      return false
    end
    return true
  end

  # SANDBOX環境へのログイン
  def auth(sandbox_email, sandbox_password)
    payload = '{ "email":"%s", "password": "%s" }' % [sandbox_email, sandbox_password]
    response = https_post("https://api-sandbox.soracom.io/v1/auth", payload)
    case response
    when Net::HTTPUnauthorized
      p response.read_body()
      return;
    end
    return response.body
  end

  def regist_payment
    dummy_card_info = '{ "cvc": "123", "expireMonth": 12, "expireYear": 20, "name": "HOGEO FUGA", "number": "4242424242424242" }'
    response = https_post_with_auth("https://api-sandbox.soracom.io/v1/payment_methods/webpay", dummy_card_info)
    case response
    when Net::HTTPOK
      return true
    end
    p response.read_body()
    return false;
  end

  def create_subscriber
      response = https_post("https://api-sandbox.soracom.io/v1/sandbox/subscribers/create")
      case response
      when Net::HTTPOK
        return response.body
      end
      p response.read_body()
      return nil
  end

  def regist_subscriber(subscriber)
    uri = "https://api-sandbox.soracom.io/v1/subscribers/%s/register" % subscriber["imsi"]
    payload = '{ "registrationSecret":"%s" }' % subscriber["registrationSecret"]
    response = https_post_with_auth(uri, payload)
    case response
    when Net::HTTPOK
      return response.body
    end
    p response.read_body()
    return nil
  end

  # SORACOM API SANDBOX環境へのログインを行います。
  def login_sandbox(sandbox_emal, sandbox_password, auth_key_id, auth_key)
    if(!signup_sandbox(sandbox_emal, sandbox_password))
      return nil
    end

    token = get_signup_token(sandbox_emal, auth_key_id, auth_key)
    if(token == nil)
      return nil
    end

    if(!signup(token))
      return nil
    end

    # ログイン
    return auth(sandbox_emal, sandbox_password)
  end
end
