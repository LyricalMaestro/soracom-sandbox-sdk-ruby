require_relative '../lib/sandbox_client.rb'
require_relative 'auth_settings.rb'

# AUTH_KEY_IDとAUTH_KEYはauth_settings.rbで定義してある
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
