Chat = require 'chat'
Db = require 'db'
Dom = require 'dom'
Event = require 'event'
Obs = require 'obs'
Page = require 'page'
Plugin = require 'plugin'
Photo = require 'photo'
Server = require 'server'
Time = require 'time'
Ui = require 'ui'
{tr} = require 'i18n'

exports.render = !->
	if Plugin.userIsAdmin() and Page.state.get(0)!='user'
		if chatId = Page.state.get(0)
			Page.setActions
				icon: 'verified'
				action: !->
					Server.call 'discard', chatId
					Page.back()
			renderChat Db.admin.ref(chatId), chatId
		else
			renderList()
	else
		renderChat Db.personal.ref()

renderList = !->
	Dom.text tr("You are an admin for this happening. People requesting support will show up here.")
	Ui.list !->
		Dom.style marginTop: '8px'
		Db.admin.iterate (chat) !->
			Ui.item !->
				Ui.avatar Plugin.userAvatar chat.key()
				Dom.div !->
					Dom.style Flex: 1
					Dom.text chat.get('name')
				if unread=Db.personal.get('unread', chat.key())
					Ui.unread unread
				Dom.onTap !->
					Page.nav [chat.key()]
		Ui.item !->
			Dom.style color: Plugin.colors().highlight
			Dom.text tr("+ Request support yourself")
			Dom.onTap !->
				Page.nav ['user']

renderChat = (dataO,otherId) !->
	Dom.style
		fontSize: '90%'

	myUserId = Plugin.userId()
	if otherId
		newCount = Db.personal.peek('unread', otherId)
		if newCount
			Server.sync 'read', otherId, !->
				Db.personal.remove 'unread', otherId
	else
		Obs.peek -> Event.unread()

	Chat.renderMessages
		dataO: dataO
		newCount: newCount || 0
		content: (msg, num) !->
			return if !msg.isHash()
			byUserId = msg.get('by')

			Dom.div !->
				Dom.cls 'chat-msg'
				if byUserId is myUserId
					Dom.cls 'chat-me'
				
				Ui.avatar Plugin.userAvatar(byUserId), undefined, undefined, !->
					if otherId
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
						msgModal otherId, msg, num

	Page.setFooter !->
		Chat.renderInput
			dataO: dataO
			rpcArg: otherId


msgModal = (otherId, msg, num) !->
	time = msg.get('time')
	return if !time

	Modal = require 'modal'
	Form = require 'form'
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

				if otherId
					Dom.onTap !->
						Plugin.userInfo byUserId

			if !!Form.clipboard and clipboard = Form.clipboard()
				Ui.item !->
					Dom.text tr("Copy text")
					Dom.onTap !->
						clipboard(msg.get('text'))
						require('toast').show tr("Copied to clipboard")
						Modal.remove()

			if otherId and byUserId isnt +otherId
				read = Obs.create(null)
				Server.send 'getRead', otherId, num, read.func()
				Ui.item !->
					if !read.get()?
						Ui.spinner(24)
					else if read.get()
						Dom.text tr("Seen by %1", Plugin.userName(otherId))
					else
						Dom.text tr("Not seen by %1", Plugin.userName(otherId))

