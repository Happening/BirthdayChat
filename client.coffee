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
ChatView = require 'chatview'
DatePicker = require 'datepicker'
nextDate = require('nextDate').nd

exports.render = !->
	me = Plugin.userId()
	isAdmin = Plugin.userIsAdmin() || Plugin.ownerId()==me

#intro screen
	unless Db.shared.get 'birthdates', me
		Dom.section !->
			Dom.style #center content
				margin: '0px auto'
				maxWidth: '380px'
			Dom.p !->
				Dom.text tr 'Before you can start using this plugin, please set your birthdate:'
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
		# renderChat Db.shared.ref('chats',chatId), chatId
		ChatView.renderChat chatId
		return

#list screen
	Ui.list !->
		Dom.style marginTop: '8px'
		bds = Db.shared.get('birthdates') || {}
		Plugin.users.observeEach (user) !->
			Ui.item !->
				who = 0|user.key()
				name = Plugin.userName who
				bd = bds[who]

				Dom.style padding: '0px'

				Dom.div !->
					Dom.style
						Flex: true
						Box: 'left middle'
						padding: '12px 5px 12px 8px'
					Ui.avatar Plugin.userAvatar who
					Dom.last().style "flexShrink": 0
					Dom.div !->
						Dom.style
							margin: '0px 5px'
							width: '100%'
						if bd
							nd = nextDate(bd)
							Dom.text tr("%1 becomes %2", name, Math.round((nd-bd)/365.25))
							Dom.div !->
								Dom.style fontSize: '80%'
								Dom.text DatePicker.dayToString(nd)
						else
							Dom.text tr("%1 has no birthdate set", name)
					if who is me
						Dom.style opacity: 0.5
					else
						Obs.observe !->
							if unread = (Db.shared.get('chats', who, 'maxId')|0) - (Db.personal.get('read', who)|0)
								Ui.unread unread
						Dom.onTap !->
							Page.nav [who]
				if !bd || isAdmin || who is me
					Form.vSep()
					Icon.render
						data: 'edit'
						style: {padding: '15px'}
						onTap: !->
							Modal = require 'modal'
							newBd = bd
							Modal.show
								title: tr("%1's birthdate", name)
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
		, (user) ->
			if bds[user.key()] then nextDate(bds[user.key()]) else 9999999
	# Ui.bigButton "update", !->
	# 	Server.call("update")