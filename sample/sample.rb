require_relative '../lib/sandbox_client.rb'

# 本番環境のSAMユーザに対する認証キーとパスワードを設定。
AUTH_KEY_ID = "keyId-IPiOpVFYgEyjPqIoxjoKaCklsvdGqfTn"
AUTH_KEY = "secret-gYkX8Mp57wzgauM4tqEdnOAwidlRN9VgwCCxG8y1OgtVZQ0Og3r8A13wARlEmV4u"

sandbox_emal = "example_%d@example.com" % Time.now.to_i
SANDBOX_PASSWORD = "superStrongP@ssw0rd"
client = SandboxClient.new(sandbox_emal, SANDBOX_PASSWORD, AUTH_KEY_ID, AUTH_KEY)
p "ログイン成功!"
p "架空の課金状況の登録"
p client.regist_dummy_payment

subscribers = client.subscribers
p subscribers

p "----------------"

subscriber = client.create_new_subscribers
p subscriber

p "----------------"

subscribers = client.subscribers
p subscribers
