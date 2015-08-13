Chat = require 'chat'
DatePicker = require 'datepicker'
Db = require 'db'
Dom = require 'dom'
Form = require 'form'
Obs = require 'obs'
Page = require 'page'
Photo = require 'photo'
Plugin = require 'plugin'
Server = require 'server'
Time = require 'time'
Ui = require 'ui'
{tr} = require 'i18n'
nextDate = require('nextDate').nd

exports.renderChat = (aboutId) !->
	dataO = Db.shared.ref('chats', aboutId)
	#ensure data path exists.
	if !dataO? or !dataO.peek()?
		Server.call('makeDataO', aboutId)
		dataO = Db.shared.ref('chats', aboutId)
	Dom.style
		fontSize: '90%'

	myUserId = Plugin.userId()
	newCount = Db.personal.peek('unread', aboutId)
	if newCount
		Server.sync 'read', aboutId, !->
			Db.personal.remove 'unread', aboutId

	highlight = (text) ->
			Dom.span !->
				Dom.style color: Plugin.colors().highlight
				Dom.userText text

	name = Plugin.userName(aboutId)
	Page.setTitle tr("%1's birthday", name)
	Dom.section !->
		Dom.style textAlign: 'center'
		Dom.userText tr("These messages can be seen by everyone in the group except %1.", name)
		if Db.shared.get('birthdates')[aboutId]?
			Dom.br()
			Dom.userText tr("%1's birthday is on ", name)
			nd = nextDate Db.shared.get('birthdates')[aboutId]
			highlight DatePicker.dayToString(nd)

	Chat.renderMessages
		dataO: dataO
		newCount: newCount || 0
		content: (msg, num) !->
			return if !msg?
			return if !msg.isHash()
			byUserId = msg.get('by')

			Dom.div !->
				Dom.cls 'chat-msg'
				if byUserId is myUserId
					Dom.cls 'chat-me'
				
				Ui.avatar Plugin.userAvatar(byUserId),
					onTap: !->
						if aboutId
							Plugin.userInfo(byUserId)
	
				Dom.div !->
					Dom.cls 'chat-content'
					photoKey = msg.get('photo')
					if photoKey
						Dom.img !->
							Dom.prop 'src', Photo.url(photoKey, 200)
							Dom.onTap !->
								Page.nav !->
									Dom.style
										padding: 0
										backgroundColor: '#444'
									(require 'photoview').render
										key: photoKey
										
					else if photoKey is ''
						Dom.div !->
							Dom.cls 'chat-nophoto'
							Dom.text tr("Photo")
							Dom.br()
							Dom.text tr("removed")

					text = msg.get('text')
					Dom.userText text if text

					Dom.div !->
						Dom.cls 'chat-info'
						Dom.text Plugin.userName(byUserId)
						Dom.text " • "
						if time = msg.get('time')
							Time.deltaText time, 'short'
						else
							Dom.text tr("sending")
							Ui.dots()

					Dom.onTap !->
						msgModal aboutId, msg, num

	Page.setFooter !->
		Chat.renderInput
			typing: false
			dataO: dataO
			rpcArg: aboutId


msgModal = (aboutId, msg, num) !->
	time = msg.get('time')
	return if !time

	Modal = require 'modal'
	byUserId = msg.get('by')

	Modal.show false, !->
		Dom.div !->
			Dom.style
				margin: '-12px'
			Ui.item !->
				Ui.avatar Plugin.userAvatar(byUserId)
				Dom.div !->
					Dom.text tr("Sent by %1", Plugin.userName(byUserId))
					Dom.div !->
						Dom.style fontSize: '80%'
						Dom.text (new Date(time*1000)+'').replace(/\s[\S]+\s[\S]+$/, '')

				if aboutId
					Dom.onTap !->
						Plugin.userInfo byUserId

			if !!Form.clipboard and clipboard = Form.clipboard()
				Ui.item !->
					Dom.text tr("Copy text")
					Dom.onTap !->
						clipboard(msg.get('text'))
						require('toast').show tr("Copied to clipboard")
						Modal.remove()

			if aboutId and byUserId isnt +aboutId
				read = Obs.create(null)
				Server.send 'getRead', aboutId, num, read.func()
				Ui.item !->
					if !read.get()?
						Ui.spinner(24)
					else if read.get()
						Dom.text tr("Seen by %1", Plugin.userName(aboutId))
					else
						Dom.text tr("Not seen by %1", Plugin.userName(aboutId))
