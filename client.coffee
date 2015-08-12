Chat = require 'chat'
DatePicker = require 'datepicker'
Db = require 'db'
Dom = require 'dom'
Event = require 'event'
Form = require 'form'
Icon = require 'icon'
Obs = require 'obs'
Page = require 'page'
Photo = require 'photo'
Plugin = require 'plugin'
Server = require 'server'
Time = require 'time'
Ui = require 'ui'
{tr} = require 'i18n'

nextDate = (day) ->
	date = DatePicker.dayToDate(day)
	now = new Date()
	y = now.getFullYear()-1
	cutOffTime = now.getTime() - 3*24*3600*1000
	loop
		date.setFullYear y++
		break if date.getTime() > cutOffTime
	0|(date.getTime() / 864e5)

exports.render = !->
	me = Plugin.userId()
	isAdmin = Plugin.userIsAdmin() || Plugin.ownerId()==me
	unless Db.shared.get 'birthdates', me
		Dom.div !->
			Dom.text tr 'Before you can start using this plugin, please input your birthdate:'
			Dom.style marginBottom: '20px'
		DatePicker.date
			byYear: true
			start: 5630
			name: 'birthdate'
		Form.setPageSubmit (v) !->
			Server.sync 'setBirthdate', v.birthdate, !->
				Db.shared.set 'birthdates', me, v.birthdate
		return
	
	if (chatId=(0|Page.state.get(0))) and chatId!=me
		renderChat Db.shared.ref('chats',chatId), chatId
		return


	Ui.list !->
		Dom.style marginTop: '8px'
		bds = Db.shared.get('birthdates') || {}
		Plugin.users.observeEach (user) !->
			Ui.item !->
				who = 0|user.key()
				name = Plugin.userName who
				bd = bds[who]

				Ui.avatar Plugin.userAvatar who
				Dom.div !->
					Dom.style Flex: 1
					if bd
						nd = nextDate(bd)
						Dom.text tr("%1 becomes %2",name,Math.round((nd-bd)/365.25))
						Dom.div !->
							Dom.style fontSize: '80%'
							Dom.text DatePicker.dayToString(nd)
					else
						Dom.text tr("%1 has no birthdate set", name)
				if who==me
					Dom.style opacity: 0.5
				else
					if unread=Db.personal.get('unread', who)
						Ui.unread unread
					Dom.onTap !->
						Page.nav [who]
				if !bd || isAdmin
					Form.vSep()
					Icon.render
						data: 'edit'
						style: {padding: '15px', marginRight: '-15px'}
						onTap: !->
							Modal = require 'modal'
							newBd = bd
							Modal.show
								title: tr("%1's birthdate",name)
								content: !->
									DatePicker.date
										value: bd
										byYear: true
										start: 5630
										onChange: (v) !-> newBd = v
								cb: (action) !->
									if action
										Server.sync 'setBirthdate', newBd, who, !->
											Db.shared.set 'birthdates', who, newBd
								buttons: [false,tr('Cancel'),true,tr('Set')]
							,
		, (user) ->
			if (0|user.key())==me
				if isAdmin
					1000000000
			else
				(nextDate(bds[user.key()]) || 999999)


renderChat = (dataO,aboutId) !->
	log aboutId,'aboutId'
	Dom.style
		fontSize: '90%'

	myUserId = Plugin.userId()
	newCount = Db.personal.peek('unread', aboutId)
	if newCount
		Server.sync 'read', aboutId, !->
			Db.personal.remove 'unread', aboutId

	name = Plugin.userName(aboutId)
	Page.setTitle tr "%1's birthday",name
	Dom.div !->
		Dom.text tr 'These messages can be seen by everyone in the group except %1...', name

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
				
				Ui.avatar Plugin.userAvatar(byUserId),
					onTap:
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

