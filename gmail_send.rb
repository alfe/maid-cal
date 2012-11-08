# coding: utf-8

#天気用
require "gmail"

#パスワードなどのコンフィグファイル
load "config.rb"


def gmail_send(send_text = "")
#メール送信
maidSerif = MaidMail.new(@address)
begin
gmail = Gmail.new(@username,@password)
	gmail.deliver do
		to maidSerif.sendTo
		subject "スケジュール登録しました"
		body send_text
	end
	gmail.logout
rescue
 #出力結果テスト用
	puts
	puts "to #{maidSerif.sendTo}"
	puts "subject スケジュール登録しました"
	puts "body #{send_text}"
end
end