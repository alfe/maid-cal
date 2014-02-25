#!/usr/bin/ruby
# 読書メモ＋tips＋日記[http://blog.livedoor.jp/takaaki_bb/archives/51282880.html] を参考に

load "config.rb"

def MaidCal(subject,text)

schedule_check = ""

wday = [ '日', '月', '火', '水', '木', '金', '土' ]
one_more = 1 # エラーが出た時に再度繰り返す
err = 0 # 無限ループ回避

if text.size == 0
	exit
end

# カレンダー登録用
date		= nil
time_st	= nil
time_en	= nil
location = ''

if subject != nil
	text = " " + subject + text + " " # $` + $'で引っかからないよう空白
else
	text = " " + text + " " # $` + $'で引っかからないよう空白
end
while /\n/ =~ text
	text = text.sub(/\n/, " ")
end

# ------------------------------
# 日付をパースする
require 'date'

today = Date.today

while (one_more == 1)
	case text#.join(" ")
	when /今日\s*/
		date = today
		text = $` + $'
	
	when /(明日|あした|あす)\s*/
		date = today + 1
		text = $` + $'
	
	when /(明後日|あさって)\s*/
		date = today + 2
		text = $` + $'
	
	when /(日|月|火|水|木|金|土)曜(日)?\s*/
		# 次の○曜日
		date_offset = (wday.index($1) - today.wday + 7) % 7
		date_offset += 7 if date_offset == 0
		date = today + date_offset
		text = $` + $'
	
	when /([0-9]+\/[0-9]+\/[0-9]+)\s*/
		# yyyy/mm/dd
		datestr = $1
		text = $` + $'
	
		begin
			date = Date.parse(datestr)
		rescue ArgumentError
			next
		end
	
	when /([0-9]+\/[0-9]+)\s*/
		# mm/dd
		datestr = $1
		text = $` + $'
		
		begin
			date = Date.parse(datestr)
		rescue ArgumentError
			next
		end
	
		# 過去の日付だったら来年にする
		while date < today
			date = date >> 12
		end
	
	when /([0-9]+)月([0-9]+)日/
		# mm/dd
		datestr = $1 + "\/" + $2
		text = $` + $'
		
		begin
			date = Date.parse(datestr)
		rescue ArgumentError
			next
		end
	
		# 過去の日付だったら来年にする
		while date < today
			date = date >> 12
		end
	end
	
	one_more = 0
end

one_more = 1

# ------------------------------
# 時刻をパースする
require 'time'

while (one_more == 1)
begin
	case text
	when /([0-9]+)(:|：)([0-9]+)(～|から|-|－)([0-9]+)(:|：)([0-9]+)/
		time_st = Time.mktime(date.year, date.month, date.day, $1.to_i, $3.to_i, 0, 0)
		time_en = Time.mktime(date.year, date.month, date.day, $5.to_i, $7.to_i, 0, 0)
		text = $` + $'
	when /([0-9]+)時(～|から|-|－)([0-9]+)時/
		time_st = Time.mktime(date.year, date.month, date.day, $1.to_i, 00, 0, 0)
		time_en = Time.mktime(date.year, date.month, date.day, $3.to_i, 00, 0, 0)
		text = $` + $'
	when /([0-9]+)時半(-|から|に|～|－|)/
		time_st = Time.mktime(date.year, date.month, date.day, $1.to_i,30, 0, 0)
		time_en = time_st + 3600 # 3600秒 = 1時間
		text = $` + $'		
	end
	case text	
	when /([0-9]+)(:|：)([0-9]+)/
		time_st = Time.mktime(date.year, date.month, date.day, $1.to_i,$3.to_i, 0, 0)
		time_en = time_st + 3600 # 3600秒 = 1時間
		text = $` + $'
	when /([0-9]+)時(-|から|～|－|)/
		time_st = Time.mktime(date.year, date.month, date.day, $1.to_i,00, 0, 0)
		time_en = time_st + 3600 # 3600秒 = 1時間
		text = $` + $'

	end
rescue ArgumentError
	next
end
	one_more = 0
end

one_more = 1


# ------------------------------
# 場所をパースする
begin
	case text
	when /(＠|@|場(\s*|)所(\s*|　*|)：(\s*|　*|)|会場(\s*|)：(\s*|))(\S+)\s/
	location = $7
	text = $` + $'
	when /((場所|会場)は(,|，|、|))(\S+)(に|で|。|集合)/
	location = $4
	text = $` + $'
	when /(に|，|、|)(\S+)((に|で|)集合)(で|します|なので|に)/
	location = $2
	text = $` + $'
	end
end

# ------------------------------
# イベントをパースする

while (one_more == 1)
#*************
# 転送メール用
	case text
		when /(〉|\)|）|』|】|、|\s)(\S+)(について|の件|の(ご|御|)案内)/
			title = $2
			text = $` + $'
		when /(に|、|にて)(\S+)(を|の件|に)/
			title = $2
			text = $` + $'
	end

# タイトルをなるべく簡潔にするため余分な文章を落とす
	case title
		when /(\S+)(について|の件)/
			title = $1
		when /(に|、|にて)(\S+)(に|を|の件)/
			title = $2
	end
	case title
		when /(について|の件|に関して|を)/
			title = $`
	end

#*************
# スケジュール登録メール用
	case text
		when /^\s*(\S+)\s*$/
			title = $1
			text = $` + $'
	end
	

	if title =~ /^\s*$/ && err > 5 # タイトルに記入なし
		schedule_check += "ERROR:タイトルが入力できませんでした\n"
		schedule_check += "私にもわかるようにして、送りなおしてほしいです ><\n"
		err_code = 1
		one_more = 0
	elsif  title =~ /^\s*$/  # タイトルに記入なし
		err += 1
	else
		one_more = 0
	end
end


# ------------------------------
# 確認(テスト用)
=begin
puts "日付     ： #{date}"
puts "開始時刻 ： #{time_st}"
puts "終了時刻 ： #{time_en}"
puts "タイトル ： #{title}"
puts "場所     ： #{location}"
#puts += "*************************\n#{text}\n*************************"
=end

# ------------------------------
# 確認(出力用)
schedule_check += "日付     ： #{date}" + "\n"
schedule_check += "開始時刻 ： #{time_st}" + "\n"
schedule_check += "終了時刻 ： #{time_en}" + "\n"
schedule_check += "タイトル ： #{title}" + "\n"
schedule_check += "場所     ： #{location}" + "\n"
schedule_check += "\n"
#schedule_check += "*************************\n#{text}\n*************************\n"

# ------------------------------
# Googleアカウント設定

feed = 'http://www.google.com/calendar/feeds/default/private/full'

# ------------------------------
# カレンダー登録
require 'rubygems'
require 'gcalapi'

cal = GoogleCalendar::Calendar.new(GoogleCalendar::Service.new(@username, @password), feed)

if err_code == nil
	if time_st && time_en
		# 時刻指定の予定
		event			= cal.create_event
		event.title = title
		event.where = location
		event.st		= time_st
		event.en		= time_en
		event.save!
	else
		# 終日の予定
		event			 = cal.create_event
		event.title = title
		event.where = location
		event.st		= Time.mktime(date.year, date.month, date.day)
		event.en		= event.st
		event.allday = true
		event.save!
	end
end


return schedule_check

end # for def
