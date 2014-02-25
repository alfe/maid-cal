#coding: utf-8
require 'gmail' # https://github.com/dcparker/ruby-gmail
require 'kconv'
require 'date'

require "./MaidCal.rb"
require "./gmail_send.rb"
load "config.rb"

def dots()
	print "・ " # 進捗確認
end

schedule =""
mailFlag = 0			#メールを送信するかしないかのフラグ
schedule_check = ""	#スケジュールリスト
dots()

#gmailにログインb
gmail = Gmail.new(@username,@password)
dots()

#Workフォルダ内の未読を調べる
mail = gmail.mailbox('Work/maid-tyan').emails(:unread).map do |mail|
	dots()
	schedule = ""
	begin
	schedule += mail.body.decoded.encode("UTF-8", mail.charset)
=begin
		if !mail.text_part && !mail.html_part
			if mail.body.decoded.encode("UTF-8", mail.charset) != ""
				schedule += mail.body.decoded.encode("UTF-8", mail.charset)
			elsif mail.text_part
				schedule += mail.text_part.decoded.encode("UTF-8", mail.charset)
			elsif mail.html_part
				schedule += mail.html_part.decoded.encode("UTF-8", mail.charset)
			end
		end
=end
puts schedule
puts schedule.length


		#本文があるときだけ、
		if schedule.length > 0
			dots()
			mailFlag += 1
			schedule_check += MaidCal(mail.subject, schedule)
			#mail.mark(:unread) #読み込んだメールを未読に(テスト用)
			next
		end
		mail.mark(:unread) #使わなかったメールを未読に
	rescue
		mail.mark(:unread) #使わなかったメールを未読に
	end
end

dots()
puts mailFlag

#予定のあるときのみ送信
if mailFlag > 0
#*******メール本文**********
send_text = <<-EOS
ご主人様 メイドちゃんです♪
スケジュール受け付けましたよ。
登録内容の確認をお願いします。

#{schedule_check}
以上になります。
ではでは ﾉｼ
EOS
#*******メール本文**********

#puts send_text
gmail_send(send_text)
puts "sended"
end
